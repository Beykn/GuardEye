import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image/image.dart' as img;

class FaceVerificationPage extends StatefulWidget {
  const FaceVerificationPage({super.key});

  @override
  State<FaceVerificationPage> createState() => _FaceVerificationPageState();
}

class _FaceVerificationPageState extends State<FaceVerificationPage> {
  File? registeredImage;
  File? capturedImage;
  String resultMessage = '';
  String fullName = '';
  late Interpreter interpreter;
  late String driverId;
  bool isModelReady = false;
  bool isLoading = true;
  double loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    loadModel();
    loadDriverIdAndImage();
  }

  Future<void> loadModel() async {
    setState(() {
      isLoading = true;
      loadingProgress = 0;
    });

    // Simüle edilmiş yükleme animasyonu
    for (int i = 0; i <= 90; i += 10) {
      await Future.delayed(const Duration(milliseconds: 100));
      setState(() {
        loadingProgress = i.toDouble();
      });
    }

    interpreter =
    await Interpreter.fromAsset('facenet.tflite');

    await Future.delayed(const Duration(milliseconds: 200));
    setState(() {
      isModelReady = true;
      loadingProgress = 100;
      isLoading = false;
    });

    print(" Model başarıyla yüklendi.");
  }

  Future<void> loadDriverIdAndImage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          resultMessage = "Kullanıcı bulunamadı.";
        });
        return;
      }

      driverId = user.uid;
      print("Aktif kullanıcı doc ID: $driverId");

      final doc = await FirebaseFirestore.instance
          .collection("drivers")
          .doc(driverId)
          .get();
      final data = doc.data();

      if (data == null || data['imageBase64'] == null) {
        setState(() {
          resultMessage = "Base64 görsel bulunamadı.";
        });
        return;
      }

      final firstName = data['first_name'] ?? '';
      final lastName = data['last_name'] ?? '';
      fullName = "$firstName $lastName";
      print("Aktif kullanıcı adı: $fullName");

      Uint8List imageBytes = base64Decode(data['imageBase64']);
      final tempDir = await getTemporaryDirectory();
      File file = File('${tempDir.path}/registered.jpg');
      await file.writeAsBytes(imageBytes);

      setState(() {
        registeredImage = file;
      });
    } catch (e) {
      setState(() {
        resultMessage = "Bir hata oluştu: $e";
      });
    }
  }

  Future<void> pickImageFromCamera() async {
    if (!isModelReady) {
      print("⚠️ Model henüz yüklenmedi.");
      setState(() => resultMessage = "Model henüz yüklenmedi.");
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      print("📷 Fotoğraf başarıyla çekildi: ${pickedFile.path}");
      setState(() => capturedImage = File(pickedFile.path));
      await verifyFaces();
    } else {
      print("Fotoğraf çekilemedi.");
    }
  }

  Future<List<double>> getEmbedding(File imageFile) async {
    print("🔍 Embedding başlatılıyor: ${imageFile.path}");

    img.Image? image = img.decodeImage(await imageFile.readAsBytes());
    if (image == null) {
      print("Görüntü decode edilemedi.");
      return [];
    }

    img.Image resizedImage = img.copyResize(image, width: 112, height: 112);
    print("Görüntü 112x112'e resize edildi.");
    print("Model embedding çalıştırılıyor...");

    var input = List.generate(
      1,
          (i) => List.generate(
        112,
            (j) => List.generate(
          112,
              (k) => List.filled(3, 0.0),
        ),
      ),
    );

    for (int y = 0; y < 112; y++) {
      for (int x = 0; x < 112; x++) {
        final pixel = resizedImage.getPixelSafe(x, y);
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;

        input[0][y][x][0] = (r - 128) / 128.0;
        input[0][y][x][1] = (g - 128) / 128.0;
        input[0][y][x][2] = (b - 128) / 128.0;
      }
    }

    var output = List.filled(192, 0.0).reshape([1, 192]);
    interpreter.run(input, output);

    print("✅ Embedding tamamlandı.");
    return List<double>.from(output[0]);
  }

  double euclideanDistance(List<double> e1, List<double> e2) {
    double sum = 0.0;
    for (int i = 0; i < e1.length; i++) {
      sum += pow(e1[i] - e2[i], 2);
    }
    return sqrt(sum);
  }

  Future<void> verifyFaces() async {
    if (!isModelReady) {
      print("Model hazır değil.");
      setState(() => resultMessage = "Model henüz yüklenmedi.");
      return;
    }

    if (registeredImage == null || capturedImage == null) return;

    final emb1 = await getEmbedding(registeredImage!);
    final emb2 = await getEmbedding(capturedImage!);

    if (emb1.isEmpty || emb2.isEmpty) {
      setState(() => resultMessage = "Embedding alınamadı.");
      return;
    }

    final distance = euclideanDistance(emb1, emb2);
    print("Distance (euclidean): $distance");

    const threshold = 1.0;

    if (distance < threshold) {
      setState(() {
        resultMessage = "Doğru sürücü tespit edildi!";
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Başarılı"),
          content: const Text("✅ Doğru sürücü tespit edildi!"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Tamam"),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Uyarı"),
          content: const Text("❌ Yanlış kişi! Erişim reddedildi."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Tamam"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(fullName.isNotEmpty
            ? "Hoş geldin, $fullName"
            : "Sürücü Doğrulama"),
      ),
      body: Center(
        child: isLoading
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              "Model yükleniyor... %${loadingProgress.toInt()}",
              style: const TextStyle(color: Colors.white),
            ),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: pickImageFromCamera,
              icon: const Icon(Icons.camera_alt),
              label: const Text("Fotoğraf Çek ve Karşılaştır"),
            ),
            const SizedBox(height: 20),
            resultMessage.isNotEmpty
                ? Text(
              resultMessage,
              style: const TextStyle(
                  fontSize: 18, color: Colors.white),
              textAlign: TextAlign.center,
            )
                : const SizedBox(),
          ],
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}