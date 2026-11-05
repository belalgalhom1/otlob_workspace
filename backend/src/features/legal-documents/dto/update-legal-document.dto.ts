import { IsOptional, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class UpdateLegalDocumentDto {
  @ApiProperty({ example: 'Terms of Use (Updated)', required: false })
  @IsString()
  @IsOptional()
  title?: string;

  @ApiProperty({ example: 'الشروط والأحكام (محدث)', required: false })
  @IsString()
  @IsOptional()
  titleAr?: string;

  @ApiProperty({ example: 'Updated English content...', required: false })
  @IsString()
  @IsOptional()
  content?: string;

  @ApiProperty({ example: 'محتوى عربي محدث...', required: false })
  @IsString()
  @IsOptional()
  contentAr?: string;

  @ApiProperty({ example: '1.1', required: false })
  @IsString()
  @IsOptional()
  version?: string;
}
