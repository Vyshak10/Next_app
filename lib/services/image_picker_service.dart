import 'dart:typed_data';

export 'image_picker_service_stub.dart'
    if (dart.library.html) 'image_picker_service_web.dart'
    if (dart.library.io) 'image_picker_service_io.dart'; 