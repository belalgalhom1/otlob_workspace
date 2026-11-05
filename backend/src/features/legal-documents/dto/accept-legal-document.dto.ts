import { IsNotEmpty, IsString, IsUUID } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class AcceptLegalDocumentDto {
  @ApiProperty({ example: 'uuid-of-document' })
  @IsUUID()
  @IsNotEmpty()
  documentId: string;

  @ApiProperty({ example: '1.0' })
  @IsString()
  @IsNotEmpty()
  version: string;
}
