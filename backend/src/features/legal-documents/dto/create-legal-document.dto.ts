import { IsEnum, IsNotEmpty, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { LegalDocumentType } from '@prisma/client';

export class CreateLegalDocumentDto {
  @ApiProperty({ enum: LegalDocumentType, example: 'TERMS_OF_USE' })
  @IsEnum(LegalDocumentType)
  @IsNotEmpty()
  type: LegalDocumentType;

  @ApiProperty({ example: 'Terms of Use' })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiProperty({ example: 'الشروط والأحكام' })
  @IsString()
  @IsNotEmpty()
  titleAr: string;

  @ApiProperty({ example: 'Full legal terms content in English...' })
  @IsString()
  @IsNotEmpty()
  content: string;

  @ApiProperty({ example: 'محتوى الشروط والأحكام الكامل باللغة العربية...' })
  @IsString()
  @IsNotEmpty()
  contentAr: string;

  @ApiProperty({ example: '1.0' })
  @IsString()
  @IsNotEmpty()
  version: string;
}
