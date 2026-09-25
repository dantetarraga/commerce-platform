import { Transform, Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsIn,
  IsLatitude,
  IsLongitude,
  IsOptional,
  IsString,
  Length,
  Matches,
  MaxLength,
  ValidateNested,
} from 'class-validator';

const trim = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value);

export const ADDRESS_KINDS = ['HOME', 'WORK', 'OTHER'] as const;
export type AddressKind = (typeof ADDRESS_KINDS)[number];

/** Igual que la app (`AddressBook.maxAddresses`). */
export const MAX_ADDRESSES = 10;

export class AddressDto {
  /** Id que genera la app ("adr_1727…"). */
  @IsString()
  @Matches(/^[\w-]{1,64}$/)
  id!: string;

  @IsIn(ADDRESS_KINDS)
  kind!: AddressKind;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @MaxLength(40)
  label?: string | null;

  @Transform(trim)
  @IsString()
  @Length(4, 120, { message: 'La dirección debe tener entre 4 y 120 caracteres.' })
  street!: string;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @MaxLength(160)
  reference?: string | null;

  @IsLatitude()
  latitude!: number;

  @IsLongitude()
  longitude!: number;
}

/** La libreta completa, como la guarda la app. */
export class AddressBookDto {
  @IsOptional()
  @IsString()
  selectedId?: string | null;

  @IsArray()
  @ArrayMaxSize(MAX_ADDRESSES, { message: `Puedes guardar hasta ${MAX_ADDRESSES} direcciones.` })
  @ValidateNested({ each: true })
  @Type(() => AddressDto)
  addresses!: AddressDto[];
}
