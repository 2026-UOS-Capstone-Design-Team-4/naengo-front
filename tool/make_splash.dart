import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final src = File('assets/images/naengo_icon.png').readAsBytesSync();
  final icon = img.decodePng(src)!;

  // 아이콘을 전체 캔버스의 40% 크기로 축소
  final canvasSize = 1500;
  final iconSize = (canvasSize * 0.4).round();
  final resized = img.copyResize(icon, width: iconSize, height: iconSize);

  // 빨간 배경 캔버스 생성
  final canvas = img.Image(width: canvasSize, height: canvasSize);
  img.fill(canvas, color: img.ColorRgb8(0xFF, 0x64, 0x64));

  // 아이콘을 중앙에 합성
  final offsetX = (canvasSize - iconSize) ~/ 2;
  final offsetY = (canvasSize - iconSize) ~/ 2;
  img.compositeImage(canvas, resized, dstX: offsetX, dstY: offsetY);

  File('assets/images/naengo_splash.png')
      .writeAsBytesSync(img.encodePng(canvas));
  print('생성 완료: assets/images/naengo_splash.png');
}
