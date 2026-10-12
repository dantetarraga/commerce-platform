import { HttpStatus } from '@nestjs/common';
import { PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { AppException, ErrorCode } from '../../common/exceptions/app.exception';

/** Lo que el cliente necesita para subir el archivo directo al storage, sin pasar por la API. */
export interface SignedUpload {
  method: 'PUT';
  uploadUrl: string;
  /** Headers que van tal cual en el PUT: forman parte de la firma. */
  headers: Record<string, string>;
  /** URL definitiva, la que se guarda en `imageUrl`. */
  publicUrl: string;
  expiresAt: string;
}

/** Storage de archivos detrás de una abstracción: el proveedor se elige con `STORAGE_PROVIDER`. */
export abstract class ObjectStorage {
  abstract signUpload(key: string, contentType: string, size: number): Promise<SignedUpload>;
}

/** Sin storage configurado (desarrollo): las fotos se pegan como URL. */
export class DisabledObjectStorage extends ObjectStorage {
  signUpload(): Promise<SignedUpload> {
    throw new AppException(
      ErrorCode.STORAGE_NOT_CONFIGURED,
      HttpStatus.SERVICE_UNAVAILABLE,
      'La subida de fotos no está activada. Pega la URL de la imagen.',
    );
  }
}

export interface R2Config {
  accountId: string;
  accessKeyId: string;
  secretAccessKey: string;
  bucket: string;
  publicUrl: string;
}

const UPLOAD_TTL_SECONDS = 5 * 60;

/** Cloudflare R2 con la API de S3. Se lee desde `publicUrl` (dominio propio, sin costo de salida). */
export class R2ObjectStorage extends ObjectStorage {
  private readonly client: S3Client;

  constructor(private readonly config: R2Config) {
    super();
    this.client = new S3Client({
      region: 'auto',
      endpoint: `https://${config.accountId}.r2.cloudflarestorage.com`,
      credentials: { accessKeyId: config.accessKeyId, secretAccessKey: config.secretAccessKey },
    });
  }

  async signUpload(key: string, contentType: string, size: number): Promise<SignedUpload> {
    const cacheControl = 'public, max-age=31536000, immutable';
    const command = new PutObjectCommand({
      Bucket: this.config.bucket,
      Key: key,
      ContentType: contentType,
      ContentLength: size,
      CacheControl: cacheControl,
    });
    // Firmar tipo y tamaño: el cliente no puede subir otra cosa ni un archivo más grande.
    const uploadUrl = await getSignedUrl(this.client, command, {
      expiresIn: UPLOAD_TTL_SECONDS,
      signableHeaders: new Set(['content-type', 'content-length', 'cache-control']),
    });
    return {
      method: 'PUT',
      uploadUrl,
      headers: { 'Content-Type': contentType, 'Cache-Control': cacheControl },
      publicUrl: `${this.config.publicUrl}/${key}`,
      expiresAt: new Date(Date.now() + UPLOAD_TTL_SECONDS * 1000).toISOString(),
    };
  }
}
