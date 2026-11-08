export type MediaPresetName =
  | 'avatar'
  | 'product'
  | 'banner'
  | 'category'
  | 'chat_image'
  | 'delivery_proof'
  | 'document'
  | 'default';

export interface ImageDimensionConfig {
  width: number;
  height: number;
  quality: number;
}

export interface MediaPreset {
  maxWidth: number;
  maxHeight: number;
  fit: 'cover' | 'inside' | 'contain' | 'fill';
  quality: number;
  thumb: ImageDimensionConfig;
}

export const MEDIA_PRESETS: Record<MediaPresetName, MediaPreset> = {
  avatar: {
    maxWidth: 400,
    maxHeight: 400,
    fit: 'cover',
    quality: 80,
    thumb: {
      width: 120,
      height: 120,
      quality: 75,
    },
  },
  product: {
    maxWidth: 1080,
    maxHeight: 1080,
    fit: 'inside',
    quality: 82,
    thumb: {
      width: 300,
      height: 300,
      quality: 75,
    },
  },
  banner: {
    maxWidth: 1440,
    maxHeight: 720,
    fit: 'cover',
    quality: 80,
    thumb: {
      width: 480,
      height: 240,
      quality: 75,
    },
  },
  category: {
    maxWidth: 512,
    maxHeight: 512,
    fit: 'inside',
    quality: 82,
    thumb: {
      width: 128,
      height: 128,
      quality: 75,
    },
  },
  chat_image: {
    maxWidth: 1280,
    maxHeight: 1280,
    fit: 'inside',
    quality: 80,
    thumb: {
      width: 320,
      height: 320,
      quality: 75,
    },
  },
  delivery_proof: {
    maxWidth: 1280,
    maxHeight: 1280,
    fit: 'inside',
    quality: 75,
    thumb: {
      width: 300,
      height: 300,
      quality: 70,
    },
  },
  document: {
    maxWidth: 1600,
    maxHeight: 1600,
    fit: 'inside',
    quality: 85,
    thumb: {
      width: 300,
      height: 300,
      quality: 75,
    },
  },
  default: {
    maxWidth: 1200,
    maxHeight: 1200,
    fit: 'inside',
    quality: 80,
    thumb: {
      width: 300,
      height: 300,
      quality: 75,
    },
  },
};
