import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';
import { MAX_IMPORT_ROWS } from './catalog-import';

/** Celdas tal como vienen del archivo; el servicio las interpreta y explica cada error. */
export class ImportRowDto {
  @IsInt()
  @Min(1)
  line!: number;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  section?: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  name?: string;

  @IsOptional()
  @IsString()
  @MaxLength(600)
  description?: string;

  @IsOptional()
  @IsString()
  @MaxLength(20)
  price?: string;

  @IsOptional()
  @IsString()
  @MaxLength(20)
  stock?: string;

  @IsOptional()
  @IsString()
  @MaxLength(20)
  available?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  imageUrl?: string;
}

export class CatalogImportDto {
  @IsArray()
  @ArrayMinSize(1, { message: 'El archivo no tiene productos.' })
  @ArrayMaxSize(MAX_IMPORT_ROWS, { message: `Importa hasta ${MAX_IMPORT_ROWS} productos por archivo.` })
  @ValidateNested({ each: true })
  @Type(() => ImportRowDto)
  rows!: ImportRowDto[];

  /** `true`: solo revisa y devuelve lo que haría, sin guardar. */
  @IsOptional()
  @IsBoolean()
  dryRun?: boolean;
}
