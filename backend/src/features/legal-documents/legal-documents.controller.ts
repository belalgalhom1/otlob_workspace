import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  Query,
  Req,
  ParseUUIDPipe,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { LegalDocumentsService } from './legal-documents.service';
import { CreateLegalDocumentDto } from './dto/create-legal-document.dto';
import { UpdateLegalDocumentDto } from './dto/update-legal-document.dto';
import { AcceptLegalDocumentDto } from './dto/accept-legal-document.dto';
import { LegalDocumentQueryDto } from './dto/legal-document-query.dto';
import { Public } from '../../common/decorators/public.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { ApiStandardResponse } from '../../common/decorators/api-response.decorator';
import { LegalDocumentType, Permission } from '@prisma/client';

@ApiTags('Legal Documents')
@Controller('legal-documents')
export class LegalDocumentsController {
  constructor(private readonly service: LegalDocumentsService) {}

  // ─── Public / Client Endpoints ─────────────────────────────────────────────

  @Public()
  @ApiStandardResponse()
  @Get('active/:type')
  @ApiOperation({
    summary: 'Get the currently active, published legal document (Terms or Privacy)',
  })
  getActiveDocument(@Param('type') type: LegalDocumentType) {
    return this.service.getActiveDocument(type);
  }

  @ApiBearerAuth()
  @ApiStandardResponse()
  @Get('acceptance-status')
  @ApiOperation({
    summary: 'Check if authenticated user needs to accept the latest Terms of Use',
  })
  getAcceptanceStatus(@CurrentUser('sub') userId: string) {
    return this.service.getAcceptanceStatus(userId);
  }

  @ApiBearerAuth()
  @ApiStandardResponse()
  @Post('accept')
  @ApiOperation({
    summary: 'Accept a legal document version (records user acceptance and timestamp)',
  })
  acceptDocument(
    @CurrentUser('sub') userId: string,
    @Body() dto: AcceptLegalDocumentDto,
    @Req() req: any,
  ) {
    const rawIp = req?.headers ? req.headers['x-forwarded-for'] : null;
    const ipAddress = Array.isArray(rawIp)
      ? rawIp[0]
      : (rawIp?.split(',')[0].trim() || req?.socket?.remoteAddress);
    const userAgent = req?.headers ? req.headers['user-agent'] : null;

    return this.service.acceptDocument(userId, dto, {
      ipAddress: ipAddress || undefined,
      userAgent: userAgent || undefined,
    });
  }

  // ─── Super Admin Endpoints ─────────────────────────────────────────────────

  @ApiBearerAuth()
  @ApiStandardResponse()
  @RequirePermissions(Permission.MANAGE_SETTINGS)
  @Get('admin/all')
  @ApiOperation({
    summary: 'List all legal documents (drafts, published, archived) with stats (Admin)',
  })
  getAllDocuments(@Query() query: LegalDocumentQueryDto) {
    return this.service.getAllDocuments(query.type);
  }

  @ApiBearerAuth()
  @ApiStandardResponse()
  @RequirePermissions(Permission.MANAGE_SETTINGS)
  @Get('admin/:id')
  @ApiOperation({
    summary: 'Get single legal document details by ID (Admin)',
  })
  getDocumentById(@Param('id', ParseUUIDPipe) id: string) {
    return this.service.getDocumentById(id);
  }

  @ApiBearerAuth()
  @ApiStandardResponse()
  @RequirePermissions(Permission.MANAGE_SETTINGS)
  @Post('admin')
  @ApiOperation({
    summary: 'Create a new legal document draft (Admin)',
  })
  createDocument(
    @CurrentUser('sub') userId: string,
    @Body() dto: CreateLegalDocumentDto,
  ) {
    return this.service.createDocument(userId, dto);
  }

  @ApiBearerAuth()
  @ApiStandardResponse()
  @RequirePermissions(Permission.MANAGE_SETTINGS)
  @Patch('admin/:id')
  @ApiOperation({
    summary: 'Update legal document details (Admin)',
  })
  updateDocument(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateLegalDocumentDto,
  ) {
    return this.service.updateDocument(id, dto);
  }

  @ApiBearerAuth()
  @ApiStandardResponse()
  @RequirePermissions(Permission.MANAGE_SETTINGS)
  @Post('admin/:id/publish')
  @ApiOperation({
    summary:
      'Publish legal document version (unpublishes older versions of same type) (Admin)',
  })
  publishDocument(@Param('id', ParseUUIDPipe) id: string) {
    return this.service.publishDocument(id);
  }

  @ApiBearerAuth()
  @ApiStandardResponse()
  @RequirePermissions(Permission.MANAGE_SETTINGS)
  @Delete('admin/:id')
  @ApiOperation({
    summary: 'Soft-delete a legal document (Admin)',
  })
  deleteDocument(@Param('id', ParseUUIDPipe) id: string) {
    return this.service.deleteDocument(id);
  }

  @ApiBearerAuth()
  @ApiStandardResponse()
  @RequirePermissions(Permission.MANAGE_SETTINGS)
  @Get('admin/:id/stats')
  @ApiOperation({
    summary: 'Get user acceptance metrics and role breakdown for a document (Admin)',
  })
  getDocumentStats(@Param('id', ParseUUIDPipe) id: string) {
    return this.service.getDocumentStats(id);
  }
}
