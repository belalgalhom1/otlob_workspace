import { LegalDocumentErrors } from '../../common/constants/response.constants';
import {
  Injectable,
  NotFoundException,
  BadRequestException,
  OnModuleInit,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { LegalDocumentType } from '@prisma/client';
import { CreateLegalDocumentDto } from './dto/create-legal-document.dto';
import { UpdateLegalDocumentDto } from './dto/update-legal-document.dto';
import { AcceptLegalDocumentDto } from './dto/accept-legal-document.dto';

@Injectable()
export class LegalDocumentsService implements OnModuleInit {
  private readonly logger = new Logger(LegalDocumentsService.name);

  constructor(private readonly prisma: PrismaService) {}

  async onModuleInit() {
    await this.seedInitialDocumentsIfEmpty();
  }

  // ─── Seed Defaults ────────────────────────────────────────────────────────
  private async seedInitialDocumentsIfEmpty() {
    try {
      const existingTerms = await this.prisma.legalDocument.findFirst({
        where: { type: LegalDocumentType.TERMS_OF_USE, deletedAt: null },
      });

      if (!existingTerms) {
        this.logger.log('Seeding initial Terms of Use (v1.0)...');
        await this.prisma.legalDocument.create({
          data: {
            type: LegalDocumentType.TERMS_OF_USE,
            title: 'Terms of Use & Service Agreement',
            titleAr: 'شروط الاستخدام واتفاقية الخدمة',
            version: '1.0',
            isPublished: true,
            publishedAt: new Date(),
            content: `### 1. Introduction
Welcome to Otlob. By accessing or using our platform, mobile applications, and services, you agree to comply with and be bound by these Terms of Use. Please read them carefully before using our services.

### 2. User Accounts & Responsibilities
- Users must provide accurate, current, and complete registration information.
- You are responsible for safeguarding your account credentials and for all activities that occur under your account.
- You must immediately notify Otlob of any unauthorized use or security breach.

### 3. Orders & Deliveries
- Prices, delivery fees, and estimated arrival times are dynamically calculated and clearly displayed prior to order confirmation.
- Customers agree to pay the total amount shown at checkout using supported payment methods.
- Drivers and vendors are independent service providers adhering to the highest quality and safety standards.

### 4. Prohibited Conduct
- Any fraudulent activity, abuse of coupons, harassment of delivery drivers or vendors, or violation of applicable laws is strictly prohibited and subject to immediate account termination.

### 5. Limitation of Liability
Otlob strives to deliver exceptional service quality. However, the platform is provided on an "as is" and "as available" basis without warranties of any kind.

### 6. Modifications to Terms
We reserve the right to revise these Terms at any time. Material changes will be communicated through the platform, requiring renewed consent upon release.`,
            contentAr: `### ١. المقدمة
أهلاً بك في تطبيق اطلب. باستخدامك لمنصتنا وتطبيقاتنا وخدماتنا، فإنك تقر وتوافق على الالتزام بشروط الاستخدام هذه. يرجى قراءتها بعناية قبل استخدام الخدمة.

### ٢. حساب المستخدم والمسؤوليات
- يجب تقديم بيانات تسجيل صحيحة ودقيقة ومحدثة.
- تقع على عاتق المستخدم كامل المسؤولية للحفاظ على سرية حسابه وكلمة المرور وكافة الأنشطة الصادرة عنه.
- يرجى إخطار فريق الدعم فوراً عند الاشتباه في أي اختراق أو استخدام غير مصرح به للحساب.

### ٣. الطلبات والتوصيل
- تُحسب أسعار المنتجات ورسوم التوصيل والوقت المتوقع بدقة وتظهر بوضوح قبل تأكيد الطلب.
- يلتزم العميل بدفع إجمالي المبلغ المستحق الموضح عند إتمام الطلب عبر وسائل الدفع المعتمدة.
- شركاؤنا من المتاجر ومندوبي التوصيل يلتزمون بأعلى معايير الجودة والسلامة.

### ٤. السلوكيات المحظورة
- يُحظر تماماً أي احتيال، أو إساءة استخدام لكوبونات الخصم، أو الإساءة لمندوبي التوصيل أو المتاجر، مما يعرض الحساب للإيقاف الفوري والملاحقة القانونية.

### ٥. حدود المسؤولية
تبذل منصة اطلب أقصى جهودها لتقديم خدمة موثوقة وممتازة، وتقدم الخدمة وفق أعلى المعايير المعمول بها.

### ٦. تعديل الشروط
تحتفظ المنصة بالحق في تحديث شروط الاستخدام متى اقتضت الحاجة. وسيتم إشعار جميع المستخدمين بأي إصدار محدث لطلب الموافقة عليه مجدداً.`,
          },
        });
      }

      const existingPrivacy = await this.prisma.legalDocument.findFirst({
        where: { type: LegalDocumentType.PRIVACY_POLICY, deletedAt: null },
      });

      if (!existingPrivacy) {
        this.logger.log('Seeding initial Privacy Policy (v1.0)...');
        await this.prisma.legalDocument.create({
          data: {
            type: LegalDocumentType.PRIVACY_POLICY,
            title: 'Privacy Policy & Data Protection',
            titleAr: 'سياسة الخصوصية وحماية البيانات',
            version: '1.0',
            isPublished: true,
            publishedAt: new Date(),
            content: `### 1. Information We Collect
We collect personal information necessary to deliver our services, including name, phone number, email address, and delivery addresses. We also collect location data to enable accurate delivery tracking and route optimization.

### 2. How We Use Your Information
- To process, dispatch, and fulfill your orders accurately.
- To communicate order updates, payment confirmations, and customer support resolutions.
- To improve platform reliability, security, and personalize user recommendations.

### 3. Data Sharing & Security
- We do not sell your personal information. Information is only shared with participating vendors and assigned delivery drivers strictly to complete active orders.
- Industry-standard encryption, tokenization, and strict access controls are implemented to protect your sensitive data.

### 4. Your Rights
You have the right to review, update, or request the deletion of your personal account data at any time through application settings or by contacting customer support.`,
            contentAr: `### ١. المعلومات التي نجمعها
نقوم بجمع البيانات الشخصية الضرورية لتقديم الخدمة، مثل: الاسم، رقم الهاتف، البريد الإلكتروني، وعناوين التوصيل، بالإضافة إلى بيانات الموقع الجغرافي لتتبع وتوصيل الطلبات بدقة.

### ٢. كيف نستخدم بياناتك
- معالجة طلباتك وتوصيلها بدقة وسرعة.
- إرسال إشعارات حالة الطلب وتأكيدات الدفع ورسائل الدعم الفني.
- تحسين أداء وأمان المنصة وتخصيص تجربة الاستخدام.

### ٣. مشاركة البيانات والأمان
- نحن لا نبيع بياناتك الشخصية مطلقاً. تتم مشاركة البيانات اللازمة فقط مع المتجر ومندوب التوصيل لإتمام توصيل الطلب الحالي.
- نطبق بروتوكولات تشفير متقدمة وإجراءات أمان صارمة لحماية كافة بياناتك.

### ٤. حقوقك
يحق لك في أي وقت مراجعة بياناتك الشخصية أو تعديلها أو طلب حذف حسابك عبر إعدادات التطبيق أو عبر التواصل مع فريق الدعم.`,
          },
        });
      }
    } catch (err) {
      this.logger.warn(
        `Failed to seed legal documents: ${err?.message || err}`,
      );
    }
  }

  // ─── Public / Client Endpoints ─────────────────────────────────────────────

  async getActiveDocument(type: LegalDocumentType) {
    const doc = await this.prisma.legalDocument.findFirst({
      where: {
        type,
        isPublished: true,
        deletedAt: null,
      },
      orderBy: { publishedAt: 'desc' },
      select: {
        id: true,
        type: true,
        title: true,
        titleAr: true,
        content: true,
        contentAr: true,
        version: true,
        publishedAt: true,
        updatedAt: true,
      },
    });

    if (!doc) {
      // Trigger lazy seeding
      await this.seedInitialDocumentsIfEmpty();
      const retry = await this.prisma.legalDocument.findFirst({
        where: { type, isPublished: true, deletedAt: null },
        orderBy: { publishedAt: 'desc' },
      });
      if (!retry) {
        throw new NotFoundException(`No active ${type} document found`);
      }
      return retry;
    }

    return doc;
  }

  async getAcceptanceStatus(userId: string) {
    // 1. Get latest published Terms of Use
    const latestTerms = await this.getActiveDocument(
      LegalDocumentType.TERMS_OF_USE,
    );

    // 2. Check user's latest acceptance for Terms of Use
    const acceptance = await this.prisma.userLegalAcceptance.findFirst({
      where: {
        userId,
        documentType: LegalDocumentType.TERMS_OF_USE,
      },
      orderBy: { acceptedAt: 'desc' },
    });

    const needsAcceptance =
      !acceptance || acceptance.version !== latestTerms.version;

    return {
      needsAcceptance,
      latestTerms: {
        id: latestTerms.id,
        version: latestTerms.version,
        title: latestTerms.title,
        titleAr: latestTerms.titleAr,
        publishedAt: latestTerms.publishedAt,
      },
      userAcceptedVersion: acceptance?.version ?? null,
      acceptedAt: acceptance?.acceptedAt ?? null,
    };
  }

  async acceptDocument(
    userId: string,
    dto: AcceptLegalDocumentDto,
    meta?: { ipAddress?: string; userAgent?: string },
  ) {
    const document = await this.prisma.legalDocument.findFirst({
      where: {
        id: dto.documentId,
        deletedAt: null,
      },
    });

    if (!document) {
      throw new NotFoundException(LegalDocumentErrors.NOT_FOUND);
    }

    // Upsert acceptance record
    const record = await this.prisma.userLegalAcceptance.upsert({
      where: {
        userId_documentType_version: {
          userId,
          documentType: document.type,
          version: dto.version,
        },
      },
      update: {
        documentId: document.id,
        acceptedAt: new Date(),
        ipAddress: meta?.ipAddress,
        userAgent: meta?.userAgent,
      },
      create: {
        userId,
        documentId: document.id,
        documentType: document.type,
        version: dto.version,
        ipAddress: meta?.ipAddress,
        userAgent: meta?.userAgent,
        acceptedAt: new Date(),
      },
    });

    return {
      success: true,
      documentId: document.id,
      version: record.version,
      acceptedAt: record.acceptedAt,
    };
  }

  // ─── Super Admin Endpoints ─────────────────────────────────────────────────

  async getAllDocuments(type?: LegalDocumentType) {
    const where: any = { deletedAt: null };
    if (type) where.type = type;

    const docs = await this.prisma.legalDocument.findMany({
      where,
      orderBy: [{ isPublished: 'desc' }, { createdAt: 'desc' }],
      include: {
        createdBy: {
          select: {
            id: true,
            name: true,
            email: true,
            avatar: true,
            role: true,
          },
        },
        _count: {
          select: {
            acceptances: true,
          },
        },
      },
    });

    return docs.map((doc) => ({
      id: doc.id,
      type: doc.type,
      title: doc.title,
      titleAr: doc.titleAr,
      version: doc.version,
      isPublished: doc.isPublished,
      publishedAt: doc.publishedAt,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
      createdBy: doc.createdBy,
      acceptanceCount: doc._count.acceptances,
      contentPreview: doc.content.slice(0, 150),
      contentArPreview: doc.contentAr.slice(0, 150),
    }));
  }

  async getDocumentById(id: string) {
    const doc = await this.prisma.legalDocument.findFirst({
      where: { id, deletedAt: null },
      include: {
        createdBy: {
          select: {
            id: true,
            name: true,
            email: true,
            avatar: true,
            role: true,
          },
        },
        _count: {
          select: {
            acceptances: true,
          },
        },
      },
    });

    if (!doc) throw new NotFoundException(LegalDocumentErrors.NOT_FOUND);

    return {
      ...doc,
      acceptanceCount: doc._count.acceptances,
    };
  }

  async createDocument(userId: string, dto: CreateLegalDocumentDto) {
    // Check if same version already exists for this type
    const existing = await this.prisma.legalDocument.findFirst({
      where: {
        type: dto.type,
        version: dto.version.trim(),
        deletedAt: null,
      },
    });

    if (existing) {
      throw new BadRequestException(
        `A document with version "${dto.version}" already exists for ${dto.type}`,
      );
    }

    return this.prisma.legalDocument.create({
      data: {
        type: dto.type,
        title: dto.title.trim(),
        titleAr: dto.titleAr.trim(),
        content: dto.content.trim(),
        contentAr: dto.contentAr.trim(),
        version: dto.version.trim(),
        isPublished: false,
        createdById: userId,
      },
    });
  }

  async updateDocument(id: string, dto: UpdateLegalDocumentDto) {
    const doc = await this.prisma.legalDocument.findFirst({
      where: { id, deletedAt: null },
    });

    if (!doc) throw new NotFoundException(LegalDocumentErrors.NOT_FOUND);

    if (dto.version && dto.version.trim() !== doc.version) {
      const existing = await this.prisma.legalDocument.findFirst({
        where: {
          type: doc.type,
          version: dto.version.trim(),
          id: { not: id },
          deletedAt: null,
        },
      });

      if (existing) {
        throw new BadRequestException(
          `Version "${dto.version}" is already in use for ${doc.type}`,
        );
      }
    }

    return this.prisma.legalDocument.update({
      where: { id },
      data: {
        title: dto.title?.trim(),
        titleAr: dto.titleAr?.trim(),
        content: dto.content?.trim(),
        contentAr: dto.contentAr?.trim(),
        version: dto.version?.trim(),
      },
    });
  }

  async publishDocument(id: string) {
    const doc = await this.prisma.legalDocument.findFirst({
      where: { id, deletedAt: null },
    });

    if (!doc) throw new NotFoundException(LegalDocumentErrors.NOT_FOUND);

    return this.prisma.$transaction(async (tx) => {
      // Unpublish all existing published docs of this type
      await tx.legalDocument.updateMany({
        where: {
          type: doc.type,
          isPublished: true,
          id: { not: id },
        },
        data: {
          isPublished: false,
        },
      });

      // Publish this document
      return tx.legalDocument.update({
        where: { id },
        data: {
          isPublished: true,
          publishedAt: new Date(),
        },
      });
    });
  }

  async deleteDocument(id: string) {
    const doc = await this.prisma.legalDocument.findFirst({
      where: { id, deletedAt: null },
    });

    if (!doc) throw new NotFoundException(LegalDocumentErrors.NOT_FOUND);

    if (doc.isPublished) {
      // Check if there is another published version
      const others = await this.prisma.legalDocument.count({
        where: {
          type: doc.type,
          isPublished: true,
          id: { not: id },
          deletedAt: null,
        },
      });

      if (others === 0) {
        throw new BadRequestException(
          'Cannot delete the currently active published document. Publish an alternative version first.',
        );
      }
    }

    // Soft delete
    await this.prisma.legalDocument.update({
      where: { id },
      data: {
        deletedAt: new Date(),
        isPublished: false,
      },
    });

    return { success: true, id };
  }

  async getDocumentStats(id: string) {
    const doc = await this.prisma.legalDocument.findFirst({
      where: { id, deletedAt: null },
    });

    if (!doc) throw new NotFoundException(LegalDocumentErrors.NOT_FOUND);

    const totalAcceptances = await this.prisma.userLegalAcceptance.count({
      where: { documentId: id },
    });

    // Breakdown by role
    const acceptances = await this.prisma.userLegalAcceptance.findMany({
      where: { documentId: id },
      select: {
        acceptedAt: true,
        user: {
          select: {
            role: true,
          },
        },
      },
    });

    const roleBreakdown: Record<string, number> = {
      CUSTOMER: 0,
      DRIVER: 0,
      VENDOR_MEMBER: 0,
      ADMIN: 0,
      SUPER_ADMIN: 0,
    };

    for (const a of acceptances) {
      const r = a.user?.role || 'OTHER';
      roleBreakdown[r] = (roleBreakdown[r] || 0) + 1;
    }

    return {
      documentId: id,
      version: doc.version,
      type: doc.type,
      totalAcceptances,
      roleBreakdown,
    };
  }
}
