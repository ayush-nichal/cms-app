import 'package:flutter/material.dart';

class ContentTypeTranslator {

  static const Map<String, Map<String, String>> _translations = {
    'text_post': {
      'YouTube': 'Community Post',
      'Instagram': 'Text Post',
      'LinkedIn': 'Professional Update',
      'Twitter': 'Tweet',
      'TikTok': 'Text Post',
      'Facebook': 'Text Post',
      'Telegram': 'Message',
      'default': 'Text Post',
    },
    'image_post': {
      'YouTube': 'Image Post',
      'Instagram': 'Standard Post',
      'LinkedIn': 'Photo Update',
      'Twitter': 'Image Tweet',
      'TikTok': 'Image Post',
      'Facebook': 'Photo Post',
      'Telegram': 'Photo',
      'default': 'Image Post',
    },
    'short_form_video': {
      'YouTube': 'YouTube Short',
      'Instagram': 'IG Reel',
      'LinkedIn': 'Short Video',
      'Twitter': 'Video Tweet',
      'TikTok': 'TikTok Video',
      'Facebook': 'FB Reel',
      'Telegram': 'Video Note',
      'default': 'Short Video',
    },
    'long_form_video': {
      'YouTube': 'Standard Video',
      'Instagram': 'Standard Video',
      'LinkedIn': 'Video Update',
      'Twitter': 'Video',
      'TikTok': 'Long Video',
      'Facebook': 'Video Post',
      'Telegram': 'Video',
      'default': 'Long Video',
    },
    'carousel_post': {
      'YouTube': '', // not supported
      'Instagram': 'Carousel Post',
      'LinkedIn': 'Document / Carousel',
      'Twitter': '', // not supported
      'TikTok': '', // not supported
      'Facebook': 'Carousel Post',
      'Telegram': '', // not supported
      'default': 'Carousel Post',
    },
  };

  static String translate(String primitive, String platformName) {
    final mapping = _translations[primitive];
    if (mapping == null) return 'Unknown';
    final result = mapping[platformName];
    if (result == null || result.isEmpty) return mapping['default']!;
    return result;
  }

  static bool isSupported(String primitive, String platformName) {
    final mapping = _translations[primitive];
    if (mapping == null) return false;
    final result = mapping[platformName];
    return !(result != null && result.isEmpty);
  }

  static Color getColor(String primitive) {
    switch (primitive) {
      case 'text_post':
        return Colors.purple.shade400;
      case 'image_post':
        return Colors.blue.shade500;
      case 'short_form_video':
        return Colors.green.shade600;
      case 'long_form_video':
        return Colors.orange.shade600;
      case 'carousel_post':
        return Colors.pink.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  static IconData getIcon(String primitive) {
    switch (primitive) {
      case 'text_post':
        return Icons.text_fields;
      case 'image_post':
        return Icons.image;
      case 'short_form_video':
        return Icons.slow_motion_video;
      case 'long_form_video':
        return Icons.videocam;
      case 'carousel_post':
        return Icons.view_carousel;
      default:
        return Icons.help_outline;
    }
  }
}
