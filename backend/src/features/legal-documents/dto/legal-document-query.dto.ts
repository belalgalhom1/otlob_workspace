import { IsEnum, IsOptional } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { LegalDocumentType } from '@prisma/client';

export class LegalDocumentQueryDto {
  @ApiProperty({ enum: LegalDocumentType, required: false })
  @IsEnum(LegalDocumentType)
  @IsOptional()
  type?: LegalDocumentType;
}
