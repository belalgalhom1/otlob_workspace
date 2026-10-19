node : Loaded Prisma config from prisma.config.ts.
node : Loaded Prisma config from prisma.config.ts.
At line:1 char:13
At line:1 char:13
+ cd backend; node node_modules/prisma/build/index.js migrate diff --fr ...
+ cd backend; node node_modules/prisma/build/index.js migrate diff --fr ...
+             ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+             ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (Loaded Prisma c...isma.config.ts.:String) [], RemoteException
    + CategoryInfo          : NotSpecified: (Loaded Prisma c...isma.config.ts.:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
    + FullyQualifiedErrorId : NativeCommandError
 
 


-- CreateSchema
-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";
CREATE SCHEMA IF NOT EXISTS "public";


-- CreateExtension
-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";


-- CreateExtension
-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";


-- CreateExtension
-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "postgis";


-- CreateEnum
-- CreateEnum
CREATE TYPE "CoinTransactionType" AS ENUM ('EARNED', 'SPENT', 'REFUNDED');
CREATE TYPE "CoinTransactionType" AS ENUM ('EARNED', 'SPENT', 'REFUNDED');


-- CreateEnum
-- CreateEnum
CREATE TYPE "DevicePlatform" AS ENUM ('ANDROID', 'IOS', 'WEB');
CREATE TYPE "DevicePlatform" AS ENUM ('ANDROID', 'IOS', 'WEB');


-- CreateEnum
-- CreateEnum
CREATE TYPE "Language" AS ENUM ('EN', 'AR');
CREATE TYPE "Language" AS ENUM ('EN', 'AR');


-- CreateEnum
-- CreateEnum
CREATE TYPE "Role" AS ENUM ('CUSTOMER', 'DRIVER', 'VENDOR_MEMBER', 'ADMIN', 'SUPER_ADMIN');
CREATE TYPE "Role" AS ENUM ('CUSTOMER', 'DRIVER', 'VENDOR_MEMBER', 'ADMIN', 'SUPER_ADMIN');


-- CreateEnum
-- CreateEnum
CREATE TYPE "Permission" AS ENUM ('MANAGE_ORDERS', 'MANAGE_PRODUCTS', 'MANAGE_VENDORS', 'MANAGE_DRIVERS', 'MANAGE_CUSTOMERS', 'MANAGE_TICKETS', 'MANAGE_CONVERSATIONS', 'VIEW_STATISTICS', 'MANAGE_SETTINGS', 'MANAGE_USERS', 'VIEW_FINANCIALS', 'MANAGE_FINANCE', 'MANAGE_PROMOTIONS', 'MANAGE_ANNOUNCEMENTS', 'VIEW_AUDIT_LOGS');
CREATE TYPE "Permission" AS ENUM ('MANAGE_ORDERS', 'MANAGE_PRODUCTS', 'MANAGE_VENDORS', 'MANAGE_DRIVERS', 'MANAGE_CUSTOMERS', 'MANAGE_TICKETS', 'MANAGE_CONVERSATIONS', 'VIEW_STATISTICS', 'MANAGE_SETTINGS', 'MANAGE_USERS', 'VIEW_FINANCIALS', 'MANAGE_FINANCE', 'MANAGE_PROMOTIONS', 'MANAGE_ANNOUNCEMENTS', 'VIEW_AUDIT_LOGS');


-- CreateEnum
-- CreateEnum
CREATE TYPE "ConversationStatus" AS ENUM ('OPEN', 'CLOSED', 'ARCHIVED');
CREATE TYPE "ConversationStatus" AS ENUM ('OPEN', 'CLOSED', 'ARCHIVED');


-- CreateEnum
-- CreateEnum
CREATE TYPE "NotificationType" AS ENUM ('ORDER_UPDATE', 'CHAT_MESSAGE', 'PROMOTION', 'SYSTEM', 'PAYMENT', 'TICKET_UPDATE', 'ANNOUNCEMENT');
CREATE TYPE "NotificationType" AS ENUM ('ORDER_UPDATE', 'CHAT_MESSAGE', 'PROMOTION', 'SYSTEM', 'PAYMENT', 'TICKET_UPDATE', 'ANNOUNCEMENT');


-- CreateEnum
-- CreateEnum
CREATE TYPE "MessageType" AS ENUM ('TEXT', 'IMAGE', 'VIDEO', 'AUDIO', 'LOCATION', 'SYSTEM', 'PRODUCT');
CREATE TYPE "MessageType" AS ENUM ('TEXT', 'IMAGE', 'VIDEO', 'AUDIO', 'LOCATION', 'SYSTEM', 'PRODUCT');


-- CreateEnum
-- CreateEnum
CREATE TYPE "ConversationType" AS ENUM ('ORDER', 'SUPPORT', 'VENDOR');
CREATE TYPE "ConversationType" AS ENUM ('ORDER', 'SUPPORT', 'VENDOR');


-- CreateEnum
-- CreateEnum
CREATE TYPE "VendorStatus" AS ENUM ('CLOSED', 'OPEN', 'PAUSED', 'SUSPENDED');
CREATE TYPE "VendorStatus" AS ENUM ('CLOSED', 'OPEN', 'PAUSED', 'SUSPENDED');


-- CreateEnum
-- CreateEnum
CREATE TYPE "VendorMemberRole" AS ENUM ('OWNER', 'MANAGER', 'STAFF');
CREATE TYPE "VendorMemberRole" AS ENUM ('OWNER', 'MANAGER', 'STAFF');


-- CreateEnum
-- CreateEnum
CREATE TYPE "VehicleType" AS ENUM ('BICYCLE', 'MOTORCYCLE', 'CAR', 'VAN', 'TRUCK', 'MOTOR_TRICYCLE');
CREATE TYPE "VehicleType" AS ENUM ('BICYCLE', 'MOTORCYCLE', 'CAR', 'VAN', 'TRUCK', 'MOTOR_TRICYCLE');


-- CreateEnum
-- CreateEnum
CREATE TYPE "DriverStatus" AS ENUM ('OFFLINE', 'ONLINE', 'BUSY', 'ON_DELIVERY', 'ON_BREAK', 'SUSPENDED');
CREATE TYPE "DriverStatus" AS ENUM ('OFFLINE', 'ONLINE', 'BUSY', 'ON_DELIVERY', 'ON_BREAK', 'SUSPENDED');


-- CreateEnum
-- CreateEnum
CREATE TYPE "DriverBreakReason" AS ENUM ('PRAYER', 'MEAL', 'REST', 'PERSONAL', 'OTHER');
CREATE TYPE "DriverBreakReason" AS ENUM ('PRAYER', 'MEAL', 'REST', 'PERSONAL', 'OTHER');


-- CreateEnum
-- CreateEnum
CREATE TYPE "DriverBreakStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED', 'ENDED');
CREATE TYPE "DriverBreakStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED', 'ENDED');


-- CreateEnum
-- CreateEnum
CREATE TYPE "DriverTier" AS ENUM ('BRONZE', 'SILVER', 'GOLD');
CREATE TYPE "DriverTier" AS ENUM ('BRONZE', 'SILVER', 'GOLD');


-- CreateEnum
-- CreateEnum
CREATE TYPE "SwapRequestStatus" AS ENUM ('PENDING', 'ACCEPTED', 'CANCELLED');
CREATE TYPE "SwapRequestStatus" AS ENUM ('PENDING', 'ACCEPTED', 'CANCELLED');


-- CreateEnum
-- CreateEnum
CREATE TYPE "DriverShiftStatus" AS ENUM ('SCHEDULED', 'ACTIVE', 'COMPLETED', 'CANCELLED', 'MISSED');
CREATE TYPE "DriverShiftStatus" AS ENUM ('SCHEDULED', 'ACTIVE', 'COMPLETED', 'CANCELLED', 'MISSED');


-- CreateEnum
-- CreateEnum
CREATE TYPE "WalletTransactionType" AS ENUM ('DELIVERY_FEE', 'CASH_COLLECTED', 'CASH_HANDED_TO_VENDOR', 'PAYOUT', 'PENALTY', 'BONUS', 'ADJUSTMENT');
CREATE TYPE "WalletTransactionType" AS ENUM ('DELIVERY_FEE', 'CASH_COLLECTED', 'CASH_HANDED_TO_VENDOR', 'PAYOUT', 'PENALTY', 'BONUS', 'ADJUSTMENT');


-- CreateEnum
-- CreateEnum
CREATE TYPE "VendorTransactionType" AS ENUM ('ORDER_REVENUE', 'COMMISSION_DEDUCTION', 'CASH_COLLECTED', 'PAYOUT', 'REFUND', 'ADJUSTMENT');
CREATE TYPE "VendorTransactionType" AS ENUM ('ORDER_REVENUE', 'COMMISSION_DEDUCTION', 'CASH_COLLECTED', 'PAYOUT', 'REFUND', 'ADJUSTMENT');


-- CreateEnum
-- CreateEnum
CREATE TYPE "StatisticPeriod" AS ENUM ('DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY');
CREATE TYPE "StatisticPeriod" AS ENUM ('DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY');


-- CreateEnum
-- CreateEnum
CREATE TYPE "OrderStatus" AS ENUM ('PENDING', 'CHANGES_REQUESTED', 'ACCEPTED', 'PREPARING', 'LOOKING_FOR_DRIVER', 'DRIVER_ASSIGNED', 'PENDING_PAYMENT', 'READY_FOR_PICKUP', 'PICKED_UP', 'DELIVERED', 'CANCELLED');
CREATE TYPE "OrderStatus" AS ENUM ('PENDING', 'CHANGES_REQUESTED', 'ACCEPTED', 'PREPARING', 'LOOKING_FOR_DRIVER', 'DRIVER_ASSIGNED', 'PENDING_PAYMENT', 'READY_FOR_PICKUP', 'PICKED_UP', 'DELIVERED', 'CANCELLED');


-- CreateEnum
-- CreateEnum
CREATE TYPE "OrderType" AS ENUM ('STANDARD', 'CUSTOM_DELIVERY', 'RIDE');
CREATE TYPE "OrderType" AS ENUM ('STANDARD', 'CUSTOM_DELIVERY', 'RIDE');


-- CreateEnum
-- CreateEnum
CREATE TYPE "OrderVendorFulfillmentStatus" AS ENUM ('PENDING', 'ACCEPTED', 'REJECTED', 'CANCELLED');
CREATE TYPE "OrderVendorFulfillmentStatus" AS ENUM ('PENDING', 'ACCEPTED', 'REJECTED', 'CANCELLED');


-- CreateEnum
-- CreateEnum
CREATE TYPE "DeliveryGroupStatus" AS ENUM ('PENDING', 'ACCEPTED', 'LOOKING_FOR_DRIVER', 'DRIVER_ASSIGNED', 'PENDING_PAYMENT', 'READY_FOR_PICKUP', 'PICKED_UP', 'DELIVERED', 'CANCELLED');
CREATE TYPE "DeliveryGroupStatus" AS ENUM ('PENDING', 'ACCEPTED', 'LOOKING_FOR_DRIVER', 'DRIVER_ASSIGNED', 'PENDING_PAYMENT', 'READY_FOR_PICKUP', 'PICKED_UP', 'DELIVERED', 'CANCELLED');


-- CreateEnum
-- CreateEnum
CREATE TYPE "DriverAssistReason" AS ENUM ('TOO_LARGE', 'TOO_HEAVY', 'MULTI_STOP_COMPLEXITY', 'LONG_DISTANCE', 'ACCESS_RESTRICTED', 'OTHER');
CREATE TYPE "DriverAssistReason" AS ENUM ('TOO_LARGE', 'TOO_HEAVY', 'MULTI_STOP_COMPLEXITY', 'LONG_DISTANCE', 'ACCESS_RESTRICTED', 'OTHER');


-- CreateEnum
-- CreateEnum
CREATE TYPE "DriverAssistRequestStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'FULFILLED', 'CANCELLED');
CREATE TYPE "DriverAssistRequestStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'FULFILLED', 'CANCELLED');


-- CreateEnum
-- CreateEnum
CREATE TYPE "DispatchStatus" AS ENUM ('PENDING', 'ACCEPTED', 'REJECTED', 'EXPIRED', 'CANCELLED');
CREATE TYPE "DispatchStatus" AS ENUM ('PENDING', 'ACCEPTED', 'REJECTED', 'EXPIRED', 'CANCELLED');


-- CreateEnum
-- CreateEnum
CREATE TYPE "PaymentMethod" AS ENUM ('CASH_ON_DELIVERY', 'MOBILE_WALLET');
CREATE TYPE "PaymentMethod" AS ENUM ('CASH_ON_DELIVERY', 'MOBILE_WALLET');


-- CreateEnum
-- CreateEnum
CREATE TYPE "PaymentStatus" AS ENUM ('PENDING', 'FAILED', 'PAID', 'COMPLETED');
CREATE TYPE "PaymentStatus" AS ENUM ('PENDING', 'FAILED', 'PAID', 'COMPLETED');


-- CreateEnum
-- CreateEnum
CREATE TYPE "TicketStatus" AS ENUM ('OPEN', 'IN_PROGRESS', 'WAITING_ON_USER', 'ESCALATED', 'RESOLVED', 'CLOSED');
CREATE TYPE "TicketStatus" AS ENUM ('OPEN', 'IN_PROGRESS', 'WAITING_ON_USER', 'ESCALATED', 'RESOLVED', 'CLOSED');


-- CreateEnum
-- CreateEnum
CREATE TYPE "TicketCategory" AS ENUM ('DELIVERY', 'VENDOR', 'PAYMENT', 'ACCOUNT', 'RETURN_COMPLAINT', 'OTHER');
CREATE TYPE "TicketCategory" AS ENUM ('DELIVERY', 'VENDOR', 'PAYMENT', 'ACCOUNT', 'RETURN_COMPLAINT', 'OTHER');


-- CreateEnum
-- CreateEnum
CREATE TYPE "TicketPriority" AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'URGENT');
CREATE TYPE "TicketPriority" AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'URGENT');


-- CreateEnum
-- CreateEnum
CREATE TYPE "AuditActionType" AS ENUM ('CREATE', 'UPDATE', 'DELETE', 'OTHER');
CREATE TYPE "AuditActionType" AS ENUM ('CREATE', 'UPDATE', 'DELETE', 'OTHER');


-- CreateEnum
-- CreateEnum
CREATE TYPE "PromotionType" AS ENUM ('BANNER', 'VENDOR', 'PRODUCT', 'EXTERNAL_LINK', 'POPUP', 'NOTIFICATION');
CREATE TYPE "PromotionType" AS ENUM ('BANNER', 'VENDOR', 'PRODUCT', 'EXTERNAL_LINK', 'POPUP', 'NOTIFICATION');


-- CreateEnum
-- CreateEnum
CREATE TYPE "WalletType" AS ENUM ('VODAFONE', 'ORANGE', 'WE', 'ETISALAT', 'INSTAPAY');
CREATE TYPE "WalletType" AS ENUM ('VODAFONE', 'ORANGE', 'WE', 'ETISALAT', 'INSTAPAY');


-- CreateEnum
-- CreateEnum
CREATE TYPE "TopUpStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED');
CREATE TYPE "TopUpStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED');


-- CreateTable
-- CreateTable
CREATE TABLE "platform_settings" (
CREATE TABLE "platform_settings" (
    "id" TEXT NOT NULL DEFAULT 'default',
    "id" TEXT NOT NULL DEFAULT 'default',
    "currency" TEXT NOT NULL DEFAULT 'EGP',
    "currency" TEXT NOT NULL DEFAULT 'EGP',
    "defaultCommissionRate" INTEGER NOT NULL DEFAULT 10,
    "defaultCommissionRate" INTEGER NOT NULL DEFAULT 10,
    "deliveryCommissionRate" INTEGER NOT NULL DEFAULT 20,
    "deliveryCommissionRate" INTEGER NOT NULL DEFAULT 20,
    "defaultTaxRate" INTEGER NOT NULL DEFAULT 14,
    "defaultTaxRate" INTEGER NOT NULL DEFAULT 14,
    "minOrderAmount" INTEGER NOT NULL DEFAULT 0,
    "minOrderAmount" INTEGER NOT NULL DEFAULT 0,
    "baseDeliveryFee" INTEGER NOT NULL DEFAULT 15,
    "baseDeliveryFee" INTEGER NOT NULL DEFAULT 15,
    "pricePerKm" INTEGER NOT NULL DEFAULT 3,
    "pricePerKm" INTEGER NOT NULL DEFAULT 3,
    "pricePerKmBicycle" INTEGER NOT NULL DEFAULT 2,
    "pricePerKmBicycle" INTEGER NOT NULL DEFAULT 2,
    "pricePerKmMotorcycle" INTEGER NOT NULL DEFAULT 3,
    "pricePerKmMotorcycle" INTEGER NOT NULL DEFAULT 3,
    "pricePerKmCar" INTEGER NOT NULL DEFAULT 5,
    "pricePerKmCar" INTEGER NOT NULL DEFAULT 5,
    "pricePerKmVan" INTEGER NOT NULL DEFAULT 8,
    "pricePerKmVan" INTEGER NOT NULL DEFAULT 8,
    "pricePerKmTruck" INTEGER NOT NULL DEFAULT 12,
    "pricePerKmTruck" INTEGER NOT NULL DEFAULT 12,
    "pricePerKmMotorTricycle" INTEGER NOT NULL DEFAULT 4,
    "pricePerKmMotorTricycle" INTEGER NOT NULL DEFAULT 4,
    "maxDeliveryFee" INTEGER NOT NULL DEFAULT 0,
    "maxDeliveryFee" INTEGER NOT NULL DEFAULT 0,
    "minDeliveryFee" INTEGER NOT NULL DEFAULT 15,
    "minDeliveryFee" INTEGER NOT NULL DEFAULT 15,
    "minDeliveryFeeBicycle" INTEGER NOT NULL DEFAULT 15,
    "minDeliveryFeeBicycle" INTEGER NOT NULL DEFAULT 15,
    "maxDeliveryFeeBicycle" INTEGER NOT NULL DEFAULT 0,
    "maxDeliveryFeeBicycle" INTEGER NOT NULL DEFAULT 0,
    "minDeliveryFeeMotorcycle" INTEGER NOT NULL DEFAULT 15,
    "minDeliveryFeeMotorcycle" INTEGER NOT NULL DEFAULT 15,
    "maxDeliveryFeeMotorcycle" INTEGER NOT NULL DEFAULT 0,
    "maxDeliveryFeeMotorcycle" INTEGER NOT NULL DEFAULT 0,
    "minDeliveryFeeCar" INTEGER NOT NULL DEFAULT 15,
    "minDeliveryFeeCar" INTEGER NOT NULL DEFAULT 15,
    "maxDeliveryFeeCar" INTEGER NOT NULL DEFAULT 0,
    "maxDeliveryFeeCar" INTEGER NOT NULL DEFAULT 0,
    "minDeliveryFeeVan" INTEGER NOT NULL DEFAULT 15,
    "minDeliveryFeeVan" INTEGER NOT NULL DEFAULT 15,
    "maxDeliveryFeeVan" INTEGER NOT NULL DEFAULT 0,
    "maxDeliveryFeeVan" INTEGER NOT NULL DEFAULT 0,
    "minDeliveryFeeTruck" INTEGER NOT NULL DEFAULT 15,
    "minDeliveryFeeTruck" INTEGER NOT NULL DEFAULT 15,
    "maxDeliveryFeeTruck" INTEGER NOT NULL DEFAULT 0,
    "maxDeliveryFeeTruck" INTEGER NOT NULL DEFAULT 0,
    "minDeliveryFeeMotorTricycle" INTEGER NOT NULL DEFAULT 15,
    "minDeliveryFeeMotorTricycle" INTEGER NOT NULL DEFAULT 15,
    "maxDeliveryFeeMotorTricycle" INTEGER NOT NULL DEFAULT 0,
    "maxDeliveryFeeMotorTricycle" INTEGER NOT NULL DEFAULT 0,
    "allowBicycle" BOOLEAN NOT NULL DEFAULT true,
    "allowBicycle" BOOLEAN NOT NULL DEFAULT true,
    "allowMotorcycle" BOOLEAN NOT NULL DEFAULT true,
    "allowMotorcycle" BOOLEAN NOT NULL DEFAULT true,
    "allowCar" BOOLEAN NOT NULL DEFAULT true,
    "allowCar" BOOLEAN NOT NULL DEFAULT true,
    "allowVan" BOOLEAN NOT NULL DEFAULT true,
    "allowVan" BOOLEAN NOT NULL DEFAULT true,
    "allowTruck" BOOLEAN NOT NULL DEFAULT true,
    "allowTruck" BOOLEAN NOT NULL DEFAULT true,
    "allowMotorTricycle" BOOLEAN NOT NULL DEFAULT true,
    "allowMotorTricycle" BOOLEAN NOT NULL DEFAULT true,
    "minOrderKm" INTEGER NOT NULL DEFAULT 0,
    "minOrderKm" INTEGER NOT NULL DEFAULT 0,
    "minDistanceFixedPrice" INTEGER NOT NULL DEFAULT 0,
    "minDistanceFixedPrice" INTEGER NOT NULL DEFAULT 0,
    "maxDeliveryRadiusKm" DOUBLE PRECISION NOT NULL DEFAULT 1500,
    "maxDeliveryRadiusKm" DOUBLE PRECISION NOT NULL DEFAULT 1500,
    "driverSearchRadiusKm" DOUBLE PRECISION NOT NULL DEFAULT 5.0,
    "driverSearchRadiusKm" DOUBLE PRECISION NOT NULL DEFAULT 5.0,
    "driverSearchRadiusStepKm" DOUBLE PRECISION NOT NULL DEFAULT 2.0,
    "driverSearchRadiusStepKm" DOUBLE PRECISION NOT NULL DEFAULT 2.0,
    "driverSearchRadiusMaxKm" DOUBLE PRECISION NOT NULL DEFAULT 15.0,
    "driverSearchRadiusMaxKm" DOUBLE PRECISION NOT NULL DEFAULT 15.0,
    "autoCancelPendingMins" INTEGER NOT NULL DEFAULT 15,
    "autoCancelPendingMins" INTEGER NOT NULL DEFAULT 15,
    "mobileWalletTimeoutMins" INTEGER NOT NULL DEFAULT 15,
    "mobileWalletTimeoutMins" INTEGER NOT NULL DEFAULT 15,
    "driverAcceptTimeoutSecs" INTEGER NOT NULL DEFAULT 30,
    "driverAcceptTimeoutSecs" INTEGER NOT NULL DEFAULT 30,
    "assistDecisionTimeoutSecs" INTEGER NOT NULL DEFAULT 120,
    "assistDecisionTimeoutSecs" INTEGER NOT NULL DEFAULT 120,
    "isMaintenanceMode" BOOLEAN NOT NULL DEFAULT false,
    "isMaintenanceMode" BOOLEAN NOT NULL DEFAULT false,
    "androidMinVersion" TEXT NOT NULL DEFAULT '1.0.0',
    "androidMinVersion" TEXT NOT NULL DEFAULT '1.0.0',
    "androidLatestVersion" TEXT NOT NULL DEFAULT '1.0.0',
    "androidLatestVersion" TEXT NOT NULL DEFAULT '1.0.0',
    "androidForceUpdate" BOOLEAN NOT NULL DEFAULT false,
    "androidForceUpdate" BOOLEAN NOT NULL DEFAULT false,
    "androidStoreUrl" TEXT,
    "androidStoreUrl" TEXT,
    "iosMinVersion" TEXT NOT NULL DEFAULT '1.0.0',
    "iosMinVersion" TEXT NOT NULL DEFAULT '1.0.0',
    "iosLatestVersion" TEXT NOT NULL DEFAULT '1.0.0',
    "iosLatestVersion" TEXT NOT NULL DEFAULT '1.0.0',
    "iosForceUpdate" BOOLEAN NOT NULL DEFAULT false,
    "iosForceUpdate" BOOLEAN NOT NULL DEFAULT false,
    "iosStoreUrl" TEXT,
    "iosStoreUrl" TEXT,
    "supportEmail" TEXT,
    "supportEmail" TEXT,
    "supportPhone" TEXT,
    "supportPhone" TEXT,
    "supportWhatsapp" TEXT,
    "supportWhatsapp" TEXT,
    "termsUrl" TEXT,
    "termsUrl" TEXT,
    "privacyUrl" TEXT,
    "privacyUrl" TEXT,
    "homeCoverUrl" TEXT,
    "homeCoverUrl" TEXT,
    "motorcycleIconUrl" TEXT,
    "motorcycleIconUrl" TEXT,
    "carIconUrl" TEXT,
    "carIconUrl" TEXT,
    "bicycleIconUrl" TEXT,
    "bicycleIconUrl" TEXT,
    "motorTricycleIconUrl" TEXT,
    "motorTricycleIconUrl" TEXT,
    "vanIconUrl" TEXT,
    "vanIconUrl" TEXT,
    "truckIconUrl" TEXT,
    "truckIconUrl" TEXT,
    "deliveryBannerIconUrl" TEXT,
    "deliveryBannerIconUrl" TEXT,
    "retentionOrdersDays" INTEGER NOT NULL DEFAULT 90,
    "retentionOrdersDays" INTEGER NOT NULL DEFAULT 90,
    "retentionArchivedChatsDays" INTEGER NOT NULL DEFAULT 60,
    "retentionArchivedChatsDays" INTEGER NOT NULL DEFAULT 60,
    "retentionNotificationsDays" INTEGER NOT NULL DEFAULT 30,
    "retentionNotificationsDays" INTEGER NOT NULL DEFAULT 30,
    "retentionExpiredSessionsDays" INTEGER NOT NULL DEFAULT 7,
    "retentionExpiredSessionsDays" INTEGER NOT NULL DEFAULT 7,
    "retentionAuditLogsDays" INTEGER NOT NULL DEFAULT 180,
    "retentionAuditLogsDays" INTEGER NOT NULL DEFAULT 180,
    "retentionAbandonedCartsDays" INTEGER NOT NULL DEFAULT 7,
    "retentionAbandonedCartsDays" INTEGER NOT NULL DEFAULT 7,
    "retentionPaymentReceiptsDays" INTEGER NOT NULL DEFAULT 90,
    "retentionPaymentReceiptsDays" INTEGER NOT NULL DEFAULT 90,
    "retentionShiftStartPhotosDays" INTEGER NOT NULL DEFAULT 30,
    "retentionShiftStartPhotosDays" INTEGER NOT NULL DEFAULT 30,
    "retentionPickupPhotosDays" INTEGER NOT NULL DEFAULT 90,
    "retentionPickupPhotosDays" INTEGER NOT NULL DEFAULT 90,
    "retentionDeliveryPhotosDays" INTEGER NOT NULL DEFAULT 90,
    "retentionDeliveryPhotosDays" INTEGER NOT NULL DEFAULT 90,
    "retentionWalletTransactionsDays" INTEGER NOT NULL DEFAULT 365,
    "retentionWalletTransactionsDays" INTEGER NOT NULL DEFAULT 365,
    "retentionStatisticsDays" INTEGER NOT NULL DEFAULT 365,
    "retentionStatisticsDays" INTEGER NOT NULL DEFAULT 365,
    "maxKmForBicycle" DOUBLE PRECISION NOT NULL DEFAULT 5.0,
    "maxKmForBicycle" DOUBLE PRECISION NOT NULL DEFAULT 5.0,
    "driverSearchMaxAttempts" INTEGER NOT NULL DEFAULT 5,
    "driverSearchMaxAttempts" INTEGER NOT NULL DEFAULT 5,
    "driverSearchGeoCandidateLimit" INTEGER NOT NULL DEFAULT 200,
    "driverSearchGeoCandidateLimit" INTEGER NOT NULL DEFAULT 200,
    "driverLocationFreshnessTtlSecs" INTEGER NOT NULL DEFAULT 30,
    "driverLocationFreshnessTtlSecs" INTEGER NOT NULL DEFAULT 30,
    "driverLocationPrecisionMeters" INTEGER NOT NULL DEFAULT 0,
    "driverLocationPrecisionMeters" INTEGER NOT NULL DEFAULT 0,
    "fallbackOrderDistanceKm" DOUBLE PRECISION NOT NULL DEFAULT 3.0,
    "fallbackOrderDistanceKm" DOUBLE PRECISION NOT NULL DEFAULT 3.0,
    "groupingMaxBranchDistanceKm" DOUBLE PRECISION NOT NULL DEFAULT 5.0,
    "groupingMaxBranchDistanceKm" DOUBLE PRECISION NOT NULL DEFAULT 5.0,
    "groupingMaxVendorCustomerDistanceKm" DOUBLE PRECISION NOT NULL DEFAULT 25.0,
    "groupingMaxVendorCustomerDistanceKm" DOUBLE PRECISION NOT NULL DEFAULT 25.0,
    "customOrderPlatformFee" INTEGER NOT NULL DEFAULT 10,
    "customOrderPlatformFee" INTEGER NOT NULL DEFAULT 10,
    "maxDispatchBatchSize" INTEGER NOT NULL DEFAULT 20,
    "maxDispatchBatchSize" INTEGER NOT NULL DEFAULT 20,
    "coinValue" INTEGER NOT NULL DEFAULT 1,
    "coinValue" INTEGER NOT NULL DEFAULT 1,
    "amountSpentPerCoin" INTEGER NOT NULL DEFAULT 10,
    "amountSpentPerCoin" INTEGER NOT NULL DEFAULT 10,
    "minCoinsToUse" INTEGER NOT NULL DEFAULT 1,
    "minCoinsToUse" INTEGER NOT NULL DEFAULT 1,
    "driverBonusActive" BOOLEAN NOT NULL DEFAULT false,
    "driverBonusActive" BOOLEAN NOT NULL DEFAULT false,
    "driverBonusAmount" INTEGER NOT NULL DEFAULT 0,
    "driverBonusAmount" INTEGER NOT NULL DEFAULT 0,
    "driverBonusStartDate" TIMESTAMPTZ(3),
    "driverBonusStartDate" TIMESTAMPTZ(3),
    "driverBonusEndDate" TIMESTAMPTZ(3),
    "driverBonusEndDate" TIMESTAMPTZ(3),
    "driverBonusPaidByCustomer" BOOLEAN NOT NULL DEFAULT false,
    "driverBonusPaidByCustomer" BOOLEAN NOT NULL DEFAULT false,
    "driverShiftsEnabled" BOOLEAN NOT NULL DEFAULT false,
    "driverShiftsEnabled" BOOLEAN NOT NULL DEFAULT false,
    "breaksEnabled" BOOLEAN NOT NULL DEFAULT true,
    "breaksEnabled" BOOLEAN NOT NULL DEFAULT true,
    "maxActiveOrdersPerCustomer" INTEGER NOT NULL DEFAULT 2,
    "maxActiveOrdersPerCustomer" INTEGER NOT NULL DEFAULT 2,
    "requirePriorDeliveryForMultipleOrders" BOOLEAN NOT NULL DEFAULT true,
    "requirePriorDeliveryForMultipleOrders" BOOLEAN NOT NULL DEFAULT true,
    "maxOtpAttempts" INTEGER NOT NULL DEFAULT 5,
    "maxOtpAttempts" INTEGER NOT NULL DEFAULT 5,
    "maxNegativeDriverBalance" INTEGER NOT NULL DEFAULT 500,
    "maxNegativeDriverBalance" INTEGER NOT NULL DEFAULT 500,
    "driverSettlementOrderThreshold" INTEGER NOT NULL DEFAULT 10,
    "driverSettlementOrderThreshold" INTEGER NOT NULL DEFAULT 10,
    "maxBreakMinutesPerShift" INTEGER NOT NULL DEFAULT 60,
    "maxBreakMinutesPerShift" INTEGER NOT NULL DEFAULT 60,
    "maxBreaksPerShift" INTEGER NOT NULL DEFAULT 2,
    "maxBreaksPerShift" INTEGER NOT NULL DEFAULT 2,
    "maxSingleBreakMinutes" INTEGER NOT NULL DEFAULT 30,
    "maxSingleBreakMinutes" INTEGER NOT NULL DEFAULT 30,
    "pendingBreakExpiryMins" INTEGER NOT NULL DEFAULT 15,
    "pendingBreakExpiryMins" INTEGER NOT NULL DEFAULT 15,
    "otpExpirySeconds" INTEGER NOT NULL DEFAULT 900,
    "otpExpirySeconds" INTEGER NOT NULL DEFAULT 900,
    "bronzeTierBonusPerKm" INTEGER NOT NULL DEFAULT 0,
    "bronzeTierBonusPerKm" INTEGER NOT NULL DEFAULT 0,
    "silverTierBonusPerKm" INTEGER NOT NULL DEFAULT 0,
    "silverTierBonusPerKm" INTEGER NOT NULL DEFAULT 0,
    "goldTierBonusPerKm" INTEGER NOT NULL DEFAULT 0,
    "goldTierBonusPerKm" INTEGER NOT NULL DEFAULT 0,
    "highValueOrderThreshold" INTEGER NOT NULL DEFAULT 0,
    "highValueOrderThreshold" INTEGER NOT NULL DEFAULT 0,
    "highValueUpfrontRate" INTEGER NOT NULL DEFAULT 0,
    "highValueUpfrontRate" INTEGER NOT NULL DEFAULT 0,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,


    CONSTRAINT "platform_settings_pkey" PRIMARY KEY ("id")
    CONSTRAINT "platform_settings_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "zones" (
CREATE TABLE "zones" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "nameAr" TEXT,
    "nameAr" TEXT,
    "boundary" geometry NOT NULL,
    "boundary" geometry NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "baseDeliveryFeeOverride" INTEGER,
    "baseDeliveryFeeOverride" INTEGER,
    "minOrderAmountOverride" INTEGER,
    "minOrderAmountOverride" INTEGER,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,


    CONSTRAINT "zones_pkey" PRIMARY KEY ("id")
    CONSTRAINT "zones_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "users" (
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "email" TEXT,
    "email" TEXT,
    "phone" TEXT,
    "phone" TEXT,
    "password" TEXT,
    "password" TEXT,
    "name" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "role" "Role" NOT NULL DEFAULT 'CUSTOMER',
    "role" "Role" NOT NULL DEFAULT 'CUSTOMER',
    "title" TEXT,
    "title" TEXT,
    "titleAr" TEXT,
    "titleAr" TEXT,
    "permissions" "Permission"[],
    "permissions" "Permission"[],
    "avatar" TEXT,
    "avatar" TEXT,
    "language" "Language" NOT NULL DEFAULT 'EN',
    "language" "Language" NOT NULL DEFAULT 'EN',
    "isEmailVerified" BOOLEAN NOT NULL DEFAULT false,
    "isEmailVerified" BOOLEAN NOT NULL DEFAULT false,
    "isPhoneVerified" BOOLEAN NOT NULL DEFAULT false,
    "isPhoneVerified" BOOLEAN NOT NULL DEFAULT false,
    "isBanned" BOOLEAN NOT NULL DEFAULT false,
    "isBanned" BOOLEAN NOT NULL DEFAULT false,
    "banReason" TEXT,
    "banReason" TEXT,
    "autoReplyMessage" TEXT,
    "autoReplyMessage" TEXT,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "deletedAt" TIMESTAMPTZ(3),
    "deletedAt" TIMESTAMPTZ(3),


    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- Partial unique indexes so soft-deleted users credentials can be re-registered
DROP INDEX IF EXISTS "users_email_active_unique";
DROP INDEX IF EXISTS "users_phone_active_unique";
CREATE UNIQUE INDEX IF NOT EXISTS "users_email_active_unique"
  ON "users" ("email")
  WHERE "deletedAt" IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS "users_phone_active_unique"
  ON "users" ("phone")
  WHERE "deletedAt" IS NULL;

);


-- CreateTable
-- CreateTable
CREATE TABLE "devices" (
CREATE TABLE "devices" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "platform" "DevicePlatform" NOT NULL,
    "platform" "DevicePlatform" NOT NULL,
    "userId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "lastActive" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastActive" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,


    CONSTRAINT "devices_pkey" PRIMARY KEY ("id")
    CONSTRAINT "devices_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "sessions" (
CREATE TABLE "sessions" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "hashedRt" TEXT NOT NULL,
    "hashedRt" TEXT NOT NULL,
    "ipAddress" TEXT,
    "ipAddress" TEXT,
    "userAgent" TEXT,
    "userAgent" TEXT,
    "expiresAt" TIMESTAMPTZ(3) NOT NULL,
    "expiresAt" TIMESTAMPTZ(3) NOT NULL,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,


    CONSTRAINT "sessions_pkey" PRIMARY KEY ("id")
    CONSTRAINT "sessions_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "notifications" (
CREATE TABLE "notifications" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "titleAr" TEXT,
    "titleAr" TEXT,
    "body" TEXT,
    "body" TEXT,
    "bodyAr" TEXT,
    "bodyAr" TEXT,
    "type" "NotificationType" NOT NULL,
    "type" "NotificationType" NOT NULL,
    "isRead" BOOLEAN NOT NULL DEFAULT false,
    "isRead" BOOLEAN NOT NULL DEFAULT false,
    "data" JSONB,
    "data" JSONB,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,


    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "notification_settings" (
CREATE TABLE "notification_settings" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "pushEnabled" BOOLEAN NOT NULL DEFAULT true,
    "pushEnabled" BOOLEAN NOT NULL DEFAULT true,
    "orderUpdates" BOOLEAN NOT NULL DEFAULT true,
    "orderUpdates" BOOLEAN NOT NULL DEFAULT true,
    "chatMessages" BOOLEAN NOT NULL DEFAULT true,
    "chatMessages" BOOLEAN NOT NULL DEFAULT true,
    "promotions" BOOLEAN NOT NULL DEFAULT true,
    "promotions" BOOLEAN NOT NULL DEFAULT true,
    "system" BOOLEAN NOT NULL DEFAULT true,
    "system" BOOLEAN NOT NULL DEFAULT true,
    "ticketUpdates" BOOLEAN NOT NULL DEFAULT true,
    "ticketUpdates" BOOLEAN NOT NULL DEFAULT true,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,


    CONSTRAINT "notification_settings_pkey" PRIMARY KEY ("id")
    CONSTRAINT "notification_settings_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "conversations" (
CREATE TABLE "conversations" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "type" "ConversationType" NOT NULL DEFAULT 'ORDER',
    "type" "ConversationType" NOT NULL DEFAULT 'ORDER',
    "orderId" TEXT,
    "orderId" TEXT,
    "status" "ConversationStatus" NOT NULL DEFAULT 'OPEN',
    "status" "ConversationStatus" NOT NULL DEFAULT 'OPEN',
    "vendorId" TEXT,
    "vendorId" TEXT,
    "creatorId" TEXT,
    "creatorId" TEXT,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "deletedAt" TIMESTAMPTZ(3),
    "deletedAt" TIMESTAMPTZ(3),


    CONSTRAINT "conversations_pkey" PRIMARY KEY ("id")
    CONSTRAINT "conversations_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "conversation_participants" (
CREATE TABLE "conversation_participants" (
    "conversationId" TEXT NOT NULL,
    "conversationId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "joinedAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "joinedAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastReadAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastReadAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,


    CONSTRAINT "conversation_participants_pkey" PRIMARY KEY ("conversationId","userId")
    CONSTRAINT "conversation_participants_pkey" PRIMARY KEY ("conversationId","userId")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "messages" (
CREATE TABLE "messages" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "conversationId" TEXT NOT NULL,
    "conversationId" TEXT NOT NULL,
    "senderId" TEXT NOT NULL,
    "senderId" TEXT NOT NULL,
    "type" "MessageType" NOT NULL DEFAULT 'TEXT',
    "type" "MessageType" NOT NULL DEFAULT 'TEXT',
    "text" TEXT,
    "text" TEXT,
    "mediaUrl" TEXT,
    "mediaUrl" TEXT,
    "metadata" JSONB,
    "metadata" JSONB,
    "replyToId" TEXT,
    "replyToId" TEXT,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deletedAt" TIMESTAMPTZ(3),
    "deletedAt" TIMESTAMPTZ(3),


    CONSTRAINT "messages_pkey" PRIMARY KEY ("id")
    CONSTRAINT "messages_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "support_tickets" (
CREATE TABLE "support_tickets" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "ticketNumber" TEXT NOT NULL DEFAULT 'TKT-'::text || nextval('ticket_number_seq'::regclass),
    "ticketNumber" TEXT NOT NULL DEFAULT 'TKT-'::text || nextval('ticket_number_seq'::regclass),
    "subject" TEXT NOT NULL,
    "subject" TEXT NOT NULL,
    "description" TEXT,
    "description" TEXT,
    "status" "TicketStatus" NOT NULL DEFAULT 'OPEN',
    "status" "TicketStatus" NOT NULL DEFAULT 'OPEN',
    "category" "TicketCategory" NOT NULL DEFAULT 'OTHER',
    "category" "TicketCategory" NOT NULL DEFAULT 'OTHER',
    "subCategory" TEXT,
    "subCategory" TEXT,
    "priority" "TicketPriority" NOT NULL DEFAULT 'MEDIUM',
    "priority" "TicketPriority" NOT NULL DEFAULT 'MEDIUM',
    "creatorId" TEXT NOT NULL,
    "creatorId" TEXT NOT NULL,
    "assigneeId" TEXT,
    "assigneeId" TEXT,
    "orderId" TEXT,
    "orderId" TEXT,
    "vendorId" TEXT,
    "vendorId" TEXT,
    "conversationId" TEXT,
    "conversationId" TEXT,
    "lastStatusUpdateAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastStatusUpdateAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "escalatedAt" TIMESTAMPTZ(3),
    "escalatedAt" TIMESTAMPTZ(3),
    "metadata" JSONB,
    "metadata" JSONB,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,


    CONSTRAINT "support_tickets_pkey" PRIMARY KEY ("id")
    CONSTRAINT "support_tickets_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "customers" (
CREATE TABLE "customers" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "canOrder" BOOLEAN NOT NULL DEFAULT true,
    "canOrder" BOOLEAN NOT NULL DEFAULT true,
    "deletedAt" TIMESTAMPTZ(3),
    "deletedAt" TIMESTAMPTZ(3),
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "coinBalance" INTEGER NOT NULL DEFAULT 0,
    "coinBalance" INTEGER NOT NULL DEFAULT 0,


    CONSTRAINT "customers_pkey" PRIMARY KEY ("id")
    CONSTRAINT "customers_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "customer_coin_transactions" (
CREATE TABLE "customer_coin_transactions" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "customerId" TEXT NOT NULL,
    "customerId" TEXT NOT NULL,
    "orderId" TEXT,
    "orderId" TEXT,
    "type" "CoinTransactionType" NOT NULL,
    "type" "CoinTransactionType" NOT NULL,
    "amount" INTEGER NOT NULL,
    "amount" INTEGER NOT NULL,
    "balanceAfter" INTEGER NOT NULL,
    "balanceAfter" INTEGER NOT NULL,
    "description" TEXT,
    "description" TEXT,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,


    CONSTRAINT "customer_coin_transactions_pkey" PRIMARY KEY ("id")
    CONSTRAINT "customer_coin_transactions_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "favorite_vendors" (
CREATE TABLE "favorite_vendors" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "customerId" TEXT NOT NULL,
    "customerId" TEXT NOT NULL,
    "vendorId" TEXT NOT NULL,
    "vendorId" TEXT NOT NULL,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,


    CONSTRAINT "favorite_vendors_pkey" PRIMARY KEY ("id")
    CONSTRAINT "favorite_vendors_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "favorite_products" (
CREATE TABLE "favorite_products" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "customerId" TEXT NOT NULL,
    "customerId" TEXT NOT NULL,
    "productId" TEXT NOT NULL,
    "productId" TEXT NOT NULL,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,


    CONSTRAINT "favorite_products_pkey" PRIMARY KEY ("id")
    CONSTRAINT "favorite_products_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "addresses" (
CREATE TABLE "addresses" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "label" TEXT NOT NULL DEFAULT 'Home',
    "label" TEXT NOT NULL DEFAULT 'Home',
    "address" TEXT NOT NULL,
    "address" TEXT NOT NULL,
    "location" geometry NOT NULL,
    "location" geometry NOT NULL,
    "details" TEXT,
    "details" TEXT,
    "isDefault" BOOLEAN NOT NULL DEFAULT false,
    "isDefault" BOOLEAN NOT NULL DEFAULT false,
    "customerId" TEXT NOT NULL,
    "customerId" TEXT NOT NULL,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,


    CONSTRAINT "addresses_pkey" PRIMARY KEY ("id")
    CONSTRAINT "addresses_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "vendor_verticals" (
CREATE TABLE "vendor_verticals" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "nameAr" TEXT,
    "nameAr" TEXT,
    "slug" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "iconUrl" TEXT,
    "iconUrl" TEXT,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,


    CONSTRAINT "vendor_verticals_pkey" PRIMARY KEY ("id")
    CONSTRAINT "vendor_verticals_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "vendors" (
CREATE TABLE "vendors" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "storeName" TEXT NOT NULL,
    "storeName" TEXT NOT NULL,
    "storeNameAr" TEXT,
    "storeNameAr" TEXT,
    "slug" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "description" TEXT,
    "description" TEXT,
    "descriptionAr" TEXT,
    "descriptionAr" TEXT,
    "logo" TEXT,
    "logo" TEXT,
    "coverImage" TEXT,
    "coverImage" TEXT,
    "phone" TEXT,
    "phone" TEXT,
    "taxId" TEXT,
    "taxId" TEXT,
    "rating" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "rating" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "ratingCount" INTEGER NOT NULL DEFAULT 0,
    "ratingCount" INTEGER NOT NULL DEFAULT 0,
    "commissionRate" INTEGER NOT NULL DEFAULT 10,
    "commissionRate" INTEGER NOT NULL DEFAULT 10,
    "status" "VendorStatus" NOT NULL DEFAULT 'CLOSED',
    "status" "VendorStatus" NOT NULL DEFAULT 'CLOSED',
    "walletBalance" INTEGER NOT NULL DEFAULT 0,
    "walletBalance" INTEGER NOT NULL DEFAULT 0,
    "isContracted" BOOLEAN NOT NULL DEFAULT false,
    "isContracted" BOOLEAN NOT NULL DEFAULT false,
    "workingHours" JSONB,
    "workingHours" JSONB,
    "isScheduleActive" BOOLEAN NOT NULL DEFAULT true,
    "isScheduleActive" BOOLEAN NOT NULL DEFAULT true,
    "is24Hours" BOOLEAN NOT NULL DEFAULT false,
    "is24Hours" BOOLEAN NOT NULL DEFAULT false,
    "verticalId" TEXT NOT NULL,
    "verticalId" TEXT NOT NULL,
    "deletedAt" TIMESTAMPTZ(3),
    "deletedAt" TIMESTAMPTZ(3),
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,


    CONSTRAINT "vendors_pkey" PRIMARY KEY ("id")
    CONSTRAINT "vendors_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "vendor_members" (
CREATE TABLE "vendor_members" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "vendorId" TEXT NOT NULL,
    "vendorId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "role" "VendorMemberRole" NOT NULL DEFAULT 'STAFF',
    "role" "VendorMemberRole" NOT NULL DEFAULT 'STAFF',
    "branchId" TEXT,
    "branchId" TEXT,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,


    CONSTRAINT "vendor_members_pkey" PRIMARY KEY ("id")
    CONSTRAINT "vendor_members_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "vendor_branches" (
CREATE TABLE "vendor_branches" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "nameAr" TEXT,
    "nameAr" TEXT,
    "address" TEXT NOT NULL,
    "address" TEXT NOT NULL,
    "phone" TEXT,
    "phone" TEXT,
    "isOpen" BOOLEAN NOT NULL DEFAULT true,
    "isOpen" BOOLEAN NOT NULL DEFAULT true,
    "location" geometry NOT NULL,
    "location" geometry NOT NULL,
    "vendorId" TEXT NOT NULL,
    "vendorId" TEXT NOT NULL,
    "zoneId" TEXT NOT NULL,
    "zoneId" TEXT NOT NULL,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,


    CONSTRAINT "vendor_branches_pkey" PRIMARY KEY ("id")
    CONSTRAINT "vendor_branches_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "vendor_wallet_transactions" (
CREATE TABLE "vendor_wallet_transactions" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "vendorId" TEXT NOT NULL,
    "vendorId" TEXT NOT NULL,
    "orderId" TEXT,
    "orderId" TEXT,
    "type" "VendorTransactionType" NOT NULL,
    "type" "VendorTransactionType" NOT NULL,
    "amount" INTEGER NOT NULL,
    "amount" INTEGER NOT NULL,
    "balanceAfter" INTEGER NOT NULL,
    "balanceAfter" INTEGER NOT NULL,
    "description" TEXT,
    "description" TEXT,
    "referenceId" TEXT,
    "referenceId" TEXT,
    "idempotencyKey" TEXT,
    "idempotencyKey" TEXT,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,


    CONSTRAINT "vendor_wallet_transactions_pkey" PRIMARY KEY ("id")
    CONSTRAINT "vendor_wallet_transactions_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "vendor_statistics" (
CREATE TABLE "vendor_statistics" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "vendorId" TEXT NOT NULL,
    "vendorId" TEXT NOT NULL,
    "period" "StatisticPeriod" NOT NULL,
    "period" "StatisticPeriod" NOT NULL,
    "startDate" DATE NOT NULL,
    "startDate" DATE NOT NULL,
    "endDate" DATE NOT NULL,
    "endDate" DATE NOT NULL,
    "totalOrders" INTEGER NOT NULL DEFAULT 0,
    "totalOrders" INTEGER NOT NULL DEFAULT 0,
    "totalRevenue" INTEGER NOT NULL DEFAULT 0,
    "totalRevenue" INTEGER NOT NULL DEFAULT 0,
    "totalCommission" INTEGER NOT NULL DEFAULT 0,
    "totalCommission" INTEGER NOT NULL DEFAULT 0,
    "totalTax" INTEGER NOT NULL DEFAULT 0,
    "totalTax" INTEGER NOT NULL DEFAULT 0,
    "completedOrders" INTEGER NOT NULL DEFAULT 0,
    "completedOrders" INTEGER NOT NULL DEFAULT 0,
    "cancelledOrders" INTEGER NOT NULL DEFAULT 0,
    "cancelledOrders" INTEGER NOT NULL DEFAULT 0,
    "avgPrepTimeMins" DOUBLE PRECISION,
    "avgPrepTimeMins" DOUBLE PRECISION,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,


    CONSTRAINT "vendor_statistics_pkey" PRIMARY KEY ("id")
    CONSTRAINT "vendor_statistics_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "app_statistics" (
CREATE TABLE "app_statistics" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "period" "StatisticPeriod" NOT NULL,
    "period" "StatisticPeriod" NOT NULL,
    "startDate" DATE NOT NULL,
    "startDate" DATE NOT NULL,
    "endDate" DATE NOT NULL,
    "endDate" DATE NOT NULL,
    "totalOrders" INTEGER NOT NULL DEFAULT 0,
    "totalOrders" INTEGER NOT NULL DEFAULT 0,
    "totalAdminRevenue" INTEGER NOT NULL DEFAULT 0,
    "totalAdminRevenue" INTEGER NOT NULL DEFAULT 0,
    "totalDeliveryFees" INTEGER NOT NULL DEFAULT 0,
    "totalDeliveryFees" INTEGER NOT NULL DEFAULT 0,
    "activeCustomers" INTEGER NOT NULL DEFAULT 0,
    "activeCustomers" INTEGER NOT NULL DEFAULT 0,
    "activeDrivers" INTEGER NOT NULL DEFAULT 0,
    "activeDrivers" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,


    CONSTRAINT "app_statistics_pkey" PRIMARY KEY ("id")
    CONSTRAINT "app_statistics_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "stat_processing_markers" (
CREATE TABLE "stat_processing_markers" (
    "sourceKey" TEXT NOT NULL,
    "sourceKey" TEXT NOT NULL,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,


    CONSTRAINT "stat_processing_markers_pkey" PRIMARY KEY ("sourceKey")
    CONSTRAINT "stat_processing_markers_pkey" PRIMARY KEY ("sourceKey")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "menu_categories" (
CREATE TABLE "menu_categories" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "vendorId" TEXT NOT NULL,
    "vendorId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "nameAr" TEXT,
    "nameAr" TEXT,
    "description" TEXT,
    "description" TEXT,
    "descriptionAr" TEXT,
    "descriptionAr" TEXT,
    "iconUrl" TEXT,
    "iconUrl" TEXT,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,


    CONSTRAINT "menu_categories_pkey" PRIMARY KEY ("id")
    CONSTRAINT "menu_categories_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "products" (
CREATE TABLE "products" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "version" INTEGER NOT NULL DEFAULT 100,
    "version" INTEGER NOT NULL DEFAULT 100,
    "vendorId" TEXT NOT NULL,
    "vendorId" TEXT NOT NULL,
    "categoryId" TEXT,
    "categoryId" TEXT,
    "name" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "nameAr" TEXT,
    "nameAr" TEXT,
    "description" TEXT,
    "description" TEXT,
    "descriptionAr" TEXT,
    "descriptionAr" TEXT,
    "imageUrl" TEXT,
    "imageUrl" TEXT,
    "sellByStrip" BOOLEAN NOT NULL DEFAULT false,
    "sellByStrip" BOOLEAN NOT NULL DEFAULT false,
    "stripsPerPackage" INTEGER,
    "stripsPerPackage" INTEGER,
    "hasVariants" BOOLEAN NOT NULL DEFAULT false,
    "hasVariants" BOOLEAN NOT NULL DEFAULT false,
    "basePrice" INTEGER,
    "basePrice" INTEGER,
    "comparePrice" INTEGER,
    "comparePrice" INTEGER,
    "sku" TEXT,
    "sku" TEXT,
    "stock" INTEGER,
    "stock" INTEGER,
    "tracksStock" BOOLEAN NOT NULL DEFAULT true,
    "tracksStock" BOOLEAN NOT NULL DEFAULT true,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "isFeatured" BOOLEAN NOT NULL DEFAULT false,
    "isFeatured" BOOLEAN NOT NULL DEFAULT false,
    "deletedAt" TIMESTAMPTZ(3),
    "deletedAt" TIMESTAMPTZ(3),
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,


    CONSTRAINT "products_pkey" PRIMARY KEY ("id")
    CONSTRAINT "products_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "product_variants" (
CREATE TABLE "product_variants" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "productId" TEXT NOT NULL,
    "productId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "nameAr" TEXT,
    "nameAr" TEXT,
    "sku" TEXT,
    "sku" TEXT,
    "basePrice" INTEGER NOT NULL,
    "basePrice" INTEGER NOT NULL,
    "comparePrice" INTEGER,
    "comparePrice" INTEGER,
    "stock" INTEGER,
    "stock" INTEGER,
    "tracksStock" BOOLEAN NOT NULL DEFAULT true,
    "tracksStock" BOOLEAN NOT NULL DEFAULT true,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "version" INTEGER NOT NULL DEFAULT 100,
    "version" INTEGER NOT NULL DEFAULT 100,


    CONSTRAINT "product_variants_pkey" PRIMARY KEY ("id")
    CONSTRAINT "product_variants_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "product_option_groups" (
CREATE TABLE "product_option_groups" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "productId" TEXT,
    "productId" TEXT,
    "variantId" TEXT,
    "variantId" TEXT,
    "name" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "nameAr" TEXT,
    "nameAr" TEXT,
    "isRequired" BOOLEAN NOT NULL DEFAULT false,
    "isRequired" BOOLEAN NOT NULL DEFAULT false,
    "minSelect" INTEGER NOT NULL DEFAULT 0,
    "minSelect" INTEGER NOT NULL DEFAULT 0,
    "maxSelect" INTEGER NOT NULL DEFAULT 100,
    "maxSelect" INTEGER NOT NULL DEFAULT 100,


    CONSTRAINT "product_option_groups_pkey" PRIMARY KEY ("id")
    CONSTRAINT "product_option_groups_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "product_options" (
CREATE TABLE "product_options" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "groupId" TEXT NOT NULL,
    "groupId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "nameAr" TEXT,
    "nameAr" TEXT,
    "priceAdded" INTEGER NOT NULL DEFAULT 0,
    "priceAdded" INTEGER NOT NULL DEFAULT 0,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "isActive" BOOLEAN NOT NULL DEFAULT true,


    CONSTRAINT "product_options_pkey" PRIMARY KEY ("id")
    CONSTRAINT "product_options_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "carts" (
CREATE TABLE "carts" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "customerId" TEXT NOT NULL,
    "customerId" TEXT NOT NULL,
    "vendorId" TEXT NOT NULL,
    "vendorId" TEXT NOT NULL,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,


    CONSTRAINT "carts_pkey" PRIMARY KEY ("id")
    CONSTRAINT "carts_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "cart_items" (
CREATE TABLE "cart_items" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "cartId" TEXT NOT NULL,
    "cartId" TEXT NOT NULL,
    "productId" TEXT,
    "productId" TEXT,
    "variantId" TEXT,
    "variantId" TEXT,
    "customName" TEXT,
    "customName" TEXT,
    "customPrice" INTEGER,
    "customPrice" INTEGER,
    "customImageUrl" TEXT,
    "customImageUrl" TEXT,
    "quantity" INTEGER NOT NULL DEFAULT 1,
    "quantity" INTEGER NOT NULL DEFAULT 1,
    "selectedUnit" TEXT NOT NULL DEFAULT 'package',
    "selectedUnit" TEXT NOT NULL DEFAULT 'package',
    "specialRequest" TEXT,
    "specialRequest" TEXT,
    "optionHash" TEXT,
    "optionHash" TEXT,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,


    CONSTRAINT "cart_items_pkey" PRIMARY KEY ("id")
    CONSTRAINT "cart_items_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "cart_item_options" (
CREATE TABLE "cart_item_options" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "cartItemId" TEXT NOT NULL,
    "cartItemId" TEXT NOT NULL,
    "optionId" TEXT NOT NULL,
    "optionId" TEXT NOT NULL,


    CONSTRAINT "cart_item_options_pkey" PRIMARY KEY ("id")
    CONSTRAINT "cart_item_options_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "orders" (
CREATE TABLE "orders" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "orderNumber" TEXT NOT NULL DEFAULT 'ORD-'::text || nextval('order_number_seq'::regclass),
    "orderNumber" TEXT NOT NULL DEFAULT 'ORD-'::text || nextval('order_number_seq'::regclass),
    "clientOrderKey" TEXT,
    "clientOrderKey" TEXT,
    "type" "OrderType" NOT NULL DEFAULT 'STANDARD',
    "type" "OrderType" NOT NULL DEFAULT 'STANDARD',
    "customerId" TEXT NOT NULL,
    "customerId" TEXT NOT NULL,
    "vendorId" TEXT,
    "vendorId" TEXT,
    "vendorBranchId" TEXT,
    "vendorBranchId" TEXT,
    "driverId" TEXT,
    "driverId" TEXT,
    "zoneId" TEXT,
    "zoneId" TEXT,
    "driverShiftId" TEXT,
    "driverShiftId" TEXT,
    "assistDriverId" TEXT,
    "assistDriverId" TEXT,
    "assistDriverShiftId" TEXT,
    "assistDriverShiftId" TEXT,
    "assistFee" INTEGER,
    "assistFee" INTEGER,
    "assistCustomerApproved" BOOLEAN,
    "assistCustomerApproved" BOOLEAN,
    "assistApprovedAt" TIMESTAMPTZ(3),
    "assistApprovedAt" TIMESTAMPTZ(3),
    "status" "OrderStatus" NOT NULL DEFAULT 'PENDING',
    "status" "OrderStatus" NOT NULL DEFAULT 'PENDING',
    "paymentMethod" "PaymentMethod" NOT NULL,
    "paymentMethod" "PaymentMethod" NOT NULL,
    "paymentStatus" "PaymentStatus" NOT NULL DEFAULT 'PENDING',
    "paymentStatus" "PaymentStatus" NOT NULL DEFAULT 'PENDING',
    "deliveryAddress" TEXT NOT NULL,
    "deliveryAddress" TEXT NOT NULL,
    "deliveryLocation" geometry NOT NULL,
    "deliveryLocation" geometry NOT NULL,
    "pickupAddress" TEXT,
    "pickupAddress" TEXT,
    "pickupLocation" geometry,
    "pickupLocation" geometry,
    "itemDetails" TEXT,
    "itemDetails" TEXT,
    "requestedVehicleType" "VehicleType",
    "requestedVehicleType" "VehicleType",
    "subtotal" INTEGER NOT NULL,
    "subtotal" INTEGER NOT NULL,
    "deliveryFee" INTEGER NOT NULL,
    "deliveryFee" INTEGER NOT NULL,
    "driverBonusFee" INTEGER NOT NULL DEFAULT 0,
    "driverBonusFee" INTEGER NOT NULL DEFAULT 0,
    "serviceFee" INTEGER NOT NULL,
    "serviceFee" INTEGER NOT NULL,
    "tax" INTEGER NOT NULL,
    "tax" INTEGER NOT NULL,
    "discount" INTEGER NOT NULL DEFAULT 0,
    "discount" INTEGER NOT NULL DEFAULT 0,
    "coinsUsed" INTEGER NOT NULL DEFAULT 0,
    "coinsUsed" INTEGER NOT NULL DEFAULT 0,
    "coinsEarned" INTEGER NOT NULL DEFAULT 0,
    "coinsEarned" INTEGER NOT NULL DEFAULT 0,
    "grandTotal" INTEGER NOT NULL,
    "grandTotal" INTEGER NOT NULL,
    "upfrontAmount" INTEGER NOT NULL DEFAULT 0,
    "upfrontAmount" INTEGER NOT NULL DEFAULT 0,
    "specialRequest" TEXT,
    "specialRequest" TEXT,
    "estimatedPrepTime" INTEGER,
    "estimatedPrepTime" INTEGER,
    "distanceKm" DOUBLE PRECISION,
    "distanceKm" DOUBLE PRECISION,
    "deletedAt" TIMESTAMPTZ(3),
    "deletedAt" TIMESTAMPTZ(3),
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "acceptedAt" TIMESTAMPTZ(3),
    "acceptedAt" TIMESTAMPTZ(3),
    "preparedAt" TIMESTAMPTZ(3),
    "preparedAt" TIMESTAMPTZ(3),
    "driverAssignedAt" TIMESTAMPTZ(3),
    "driverAssignedAt" TIMESTAMPTZ(3),
    "pickedUpAt" TIMESTAMPTZ(3),
    "pickedUpAt" TIMESTAMPTZ(3),
    "pickupImageUrl" TEXT,
    "pickupImageUrl" TEXT,
    "deliveryImageUrl" TEXT,
    "deliveryImageUrl" TEXT,
    "paymentReceiptUrl" TEXT,
    "paymentReceiptUrl" TEXT,
    "actualDeliveryTime" TIMESTAMPTZ(3),
    "actualDeliveryTime" TIMESTAMPTZ(3),
    "settledAt" TIMESTAMPTZ(3),
    "settledAt" TIMESTAMPTZ(3),


    CONSTRAINT "orders_pkey" PRIMARY KEY ("id")
    CONSTRAINT "orders_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "order_status_events" (
CREATE TABLE "order_status_events" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "orderId" TEXT NOT NULL,
    "orderId" TEXT NOT NULL,
    "status" "OrderStatus" NOT NULL,
    "status" "OrderStatus" NOT NULL,
    "note" TEXT,
    "note" TEXT,
    "createdBy" TEXT,
    "createdBy" TEXT,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,


    CONSTRAINT "order_status_events_pkey" PRIMARY KEY ("id")
    CONSTRAINT "order_status_events_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "order_items" (
CREATE TABLE "order_items" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "orderId" TEXT NOT NULL,
    "orderId" TEXT NOT NULL,
    "fulfillmentId" TEXT,
    "fulfillmentId" TEXT,
    "productId" TEXT,
    "productId" TEXT,
    "variantId" TEXT,
    "variantId" TEXT,
    "productName" TEXT NOT NULL,
    "productName" TEXT NOT NULL,
    "variantName" TEXT,
    "variantName" TEXT,
    "unitPrice" INTEGER NOT NULL,
    "unitPrice" INTEGER NOT NULL,
    "quantity" INTEGER NOT NULL,
    "quantity" INTEGER NOT NULL,
    "totalPrice" INTEGER NOT NULL,
    "totalPrice" INTEGER NOT NULL,
    "specialRequest" TEXT,
    "specialRequest" TEXT,
    "selectedUnit" TEXT,
    "selectedUnit" TEXT,
    "baseUnitPrice" INTEGER,
    "baseUnitPrice" INTEGER,
    "rejectedAt" TIMESTAMPTZ(3),
    "rejectedAt" TIMESTAMPTZ(3),


    CONSTRAINT "order_items_pkey" PRIMARY KEY ("id")
    CONSTRAINT "order_items_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "order_item_options" (
CREATE TABLE "order_item_options" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "orderItemId" TEXT NOT NULL,
    "orderItemId" TEXT NOT NULL,
    "optionId" TEXT,
    "optionId" TEXT,
    "optionName" TEXT NOT NULL,
    "optionName" TEXT NOT NULL,
    "groupName" TEXT,
    "groupName" TEXT,
    "priceAdded" INTEGER NOT NULL,
    "priceAdded" INTEGER NOT NULL,


    CONSTRAINT "order_item_options_pkey" PRIMARY KEY ("id")
    CONSTRAINT "order_item_options_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "order_vendor_fulfillments" (
CREATE TABLE "order_vendor_fulfillments" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "orderId" TEXT NOT NULL,
    "orderId" TEXT NOT NULL,
    "vendorId" TEXT NOT NULL,
    "vendorId" TEXT NOT NULL,
    "vendorBranchId" TEXT,
    "vendorBranchId" TEXT,
    "status" "OrderVendorFulfillmentStatus" NOT NULL DEFAULT 'PENDING',
    "status" "OrderVendorFulfillmentStatus" NOT NULL DEFAULT 'PENDING',
    "subtotal" INTEGER NOT NULL DEFAULT 0,
    "subtotal" INTEGER NOT NULL DEFAULT 0,
    "commissionRate" INTEGER NOT NULL DEFAULT 10,
    "commissionRate" INTEGER NOT NULL DEFAULT 10,
    "rejectionCode" TEXT,
    "rejectionCode" TEXT,
    "rejectionReason" TEXT,
    "rejectionReason" TEXT,
    "rejectionReasonAr" TEXT,
    "rejectionReasonAr" TEXT,
    "decidedByUserId" TEXT,
    "decidedByUserId" TEXT,
    "decidedAt" TIMESTAMPTZ(3),
    "decidedAt" TIMESTAMPTZ(3),
    "deliveredAt" TIMESTAMPTZ(3),
    "deliveredAt" TIMESTAMPTZ(3),
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,


    CONSTRAINT "order_vendor_fulfillments_pkey" PRIMARY KEY ("id")
    CONSTRAINT "order_vendor_fulfillments_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "order_delivery_groups" (
CREATE TABLE "order_delivery_groups" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "orderId" TEXT NOT NULL,
    "orderId" TEXT NOT NULL,
    "sequence" INTEGER NOT NULL DEFAULT 1,
    "sequence" INTEGER NOT NULL DEFAULT 1,
    "status" "DeliveryGroupStatus" NOT NULL DEFAULT 'PENDING',
    "status" "DeliveryGroupStatus" NOT NULL DEFAULT 'PENDING',
    "primaryDriverId" TEXT,
    "primaryDriverId" TEXT,
    "primaryDriverShiftId" TEXT,
    "primaryDriverShiftId" TEXT,
    "assistDriverId" TEXT,
    "assistDriverId" TEXT,
    "assistDriverShiftId" TEXT,
    "assistDriverShiftId" TEXT,
    "assistFee" INTEGER,
    "assistFee" INTEGER,
    "assistCustomerApproved" BOOLEAN,
    "assistCustomerApproved" BOOLEAN,
    "assistApprovedAt" TIMESTAMPTZ(3),
    "assistApprovedAt" TIMESTAMPTZ(3),
    "assignedByUserId" TEXT,
    "assignedByUserId" TEXT,
    "assignedAt" TIMESTAMPTZ(3),
    "assignedAt" TIMESTAMPTZ(3),
    "distanceKm" DOUBLE PRECISION,
    "distanceKm" DOUBLE PRECISION,
    "deliveryFee" INTEGER NOT NULL DEFAULT 0,
    "deliveryFee" INTEGER NOT NULL DEFAULT 0,
    "estimatedPrepTime" INTEGER,
    "estimatedPrepTime" INTEGER,
    "pickupImageUrl" TEXT,
    "pickupImageUrl" TEXT,
    "deliveryImageUrl" TEXT,
    "deliveryImageUrl" TEXT,
    "pickedUpAt" TIMESTAMPTZ(3),
    "pickedUpAt" TIMESTAMPTZ(3),
    "deliveredAt" TIMESTAMPTZ(3),
    "deliveredAt" TIMESTAMPTZ(3),
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,


    CONSTRAINT "order_delivery_groups_pkey" PRIMARY KEY ("id")
    CONSTRAINT "order_delivery_groups_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "order_delivery_group_items" (
CREATE TABLE "order_delivery_group_items" (
    "deliveryGroupId" TEXT NOT NULL,
    "deliveryGroupId" TEXT NOT NULL,
    "fulfillmentId" TEXT NOT NULL,
    "fulfillmentId" TEXT NOT NULL,
    "sequence" INTEGER NOT NULL DEFAULT 1,
    "sequence" INTEGER NOT NULL DEFAULT 1,


    CONSTRAINT "order_delivery_group_items_pkey" PRIMARY KEY ("deliveryGroupId","fulfillmentId")
    CONSTRAINT "order_delivery_group_items_pkey" PRIMARY KEY ("deliveryGroupId","fulfillmentId")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "driver_assist_requests" (
CREATE TABLE "driver_assist_requests" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "driverId" TEXT NOT NULL,
    "driverId" TEXT NOT NULL,
    "orderId" TEXT NOT NULL,
    "orderId" TEXT NOT NULL,
    "deliveryGroupId" TEXT,
    "deliveryGroupId" TEXT,
    "reason" "DriverAssistReason" NOT NULL DEFAULT 'OTHER',
    "reason" "DriverAssistReason" NOT NULL DEFAULT 'OTHER',
    "note" TEXT,
    "note" TEXT,
    "status" "DriverAssistRequestStatus" NOT NULL DEFAULT 'PENDING',
    "status" "DriverAssistRequestStatus" NOT NULL DEFAULT 'PENDING',
    "assignedDriverId" TEXT,
    "assignedDriverId" TEXT,
    "reviewedByUserId" TEXT,
    "reviewedByUserId" TEXT,
    "reviewedAt" TIMESTAMPTZ(3),
    "reviewedAt" TIMESTAMPTZ(3),
    "resolvedAt" TIMESTAMPTZ(3),
    "resolvedAt" TIMESTAMPTZ(3),
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,


    CONSTRAINT "driver_assist_requests_pkey" PRIMARY KEY ("id")
    CONSTRAINT "driver_assist_requests_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "drivers" (
CREATE TABLE "drivers" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "avatar" TEXT,
    "avatar" TEXT,
    "nationalId" TEXT,
    "nationalId" TEXT,
    "licenseNumber" TEXT,
    "licenseNumber" TEXT,
    "vehicleType" "VehicleType" NOT NULL DEFAULT 'MOTORCYCLE',
    "vehicleType" "VehicleType" NOT NULL DEFAULT 'MOTORCYCLE',
    "vehiclePlate" TEXT,
    "vehiclePlate" TEXT,
    "tier" "DriverTier" NOT NULL DEFAULT 'GOLD',
    "tier" "DriverTier" NOT NULL DEFAULT 'GOLD',
    "status" "DriverStatus" NOT NULL DEFAULT 'OFFLINE',
    "status" "DriverStatus" NOT NULL DEFAULT 'OFFLINE',
    "lastLocation" geometry,
    "lastLocation" geometry,
    "lastLocationUpdate" TIMESTAMPTZ(3),
    "lastLocationUpdate" TIMESTAMPTZ(3),
    "rating" INTEGER NOT NULL DEFAULT 500,
    "rating" INTEGER NOT NULL DEFAULT 500,
    "ratingCount" INTEGER NOT NULL DEFAULT 0,
    "ratingCount" INTEGER NOT NULL DEFAULT 0,
    "totalOrders" INTEGER NOT NULL DEFAULT 0,
    "totalOrders" INTEGER NOT NULL DEFAULT 0,
    "ordersSinceSettlement" INTEGER NOT NULL DEFAULT 0,
    "ordersSinceSettlement" INTEGER NOT NULL DEFAULT 0,
    "walletBalance" INTEGER NOT NULL DEFAULT 0,
    "walletBalance" INTEGER NOT NULL DEFAULT 0,
    "hasUnpaidCommission" BOOLEAN NOT NULL DEFAULT false,
    "hasUnpaidCommission" BOOLEAN NOT NULL DEFAULT false,
    "version" INTEGER NOT NULL DEFAULT 100,
    "version" INTEGER NOT NULL DEFAULT 100,
    "deletedAt" TIMESTAMPTZ(3),
    "deletedAt" TIMESTAMPTZ(3),
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "isApproved" BOOLEAN NOT NULL DEFAULT false,
    "isApproved" BOOLEAN NOT NULL DEFAULT false,
    "approvedAt" TIMESTAMPTZ(3),
    "approvedAt" TIMESTAMPTZ(3),
    "approvedById" TEXT,
    "approvedById" TEXT,


    CONSTRAINT "drivers_pkey" PRIMARY KEY ("id")
    CONSTRAINT "drivers_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "driver_shifts" (
CREATE TABLE "driver_shifts" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "driverId" TEXT NOT NULL,
    "driverId" TEXT NOT NULL,
    "shiftPoolId" TEXT,
    "shiftPoolId" TEXT,
    "zoneId" TEXT,
    "zoneId" TEXT,
    "shiftDate" TIMESTAMPTZ(3) NOT NULL,
    "shiftDate" TIMESTAMPTZ(3) NOT NULL,
    "startTime" TIMESTAMPTZ(3) NOT NULL,
    "startTime" TIMESTAMPTZ(3) NOT NULL,
    "endTime" TIMESTAMPTZ(3) NOT NULL,
    "endTime" TIMESTAMPTZ(3) NOT NULL,
    "actualStart" TIMESTAMPTZ(3),
    "actualStart" TIMESTAMPTZ(3),
    "actualEnd" TIMESTAMPTZ(3),
    "actualEnd" TIMESTAMPTZ(3),
    "startPhotoUrl" TEXT,
    "startPhotoUrl" TEXT,
    "startingLocation" geometry,
    "startingLocation" geometry,
    "endingLocation" geometry,
    "endingLocation" geometry,
    "status" "DriverShiftStatus" NOT NULL DEFAULT 'SCHEDULED',
    "status" "DriverShiftStatus" NOT NULL DEFAULT 'SCHEDULED',
    "breakMinutes" INTEGER,
    "breakMinutes" INTEGER,
    "totalEarnings" INTEGER,
    "totalEarnings" INTEGER,
    "totalDeliveries" INTEGER,
    "totalDeliveries" INTEGER,
    "expiredDispatches" INTEGER NOT NULL DEFAULT 0,
    "expiredDispatches" INTEGER NOT NULL DEFAULT 0,
    "rejectedDispatches" INTEGER NOT NULL DEFAULT 0,
    "rejectedDispatches" INTEGER NOT NULL DEFAULT 0,
    "warningSent" BOOLEAN NOT NULL DEFAULT false,
    "warningSent" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,


    CONSTRAINT "driver_shifts_pkey" PRIMARY KEY ("id")
    CONSTRAINT "driver_shifts_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "shift_pools" (
CREATE TABLE "shift_pools" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "batchId" TEXT,
    "batchId" TEXT,
    "title" TEXT,
    "title" TEXT,
    "titleAr" TEXT,
    "titleAr" TEXT,
    "zoneId" TEXT,
    "zoneId" TEXT,
    "shiftDate" DATE NOT NULL,
    "shiftDate" DATE NOT NULL,
    "startTime" TIMESTAMPTZ(3) NOT NULL,
    "startTime" TIMESTAMPTZ(3) NOT NULL,
    "endTime" TIMESTAMPTZ(3) NOT NULL,
    "endTime" TIMESTAMPTZ(3) NOT NULL,
    "maxDrivers" INTEGER NOT NULL,
    "maxDrivers" INTEGER NOT NULL,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,


    CONSTRAINT "shift_pools_pkey" PRIMARY KEY ("id")
    CONSTRAINT "shift_pools_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "shift_pool_waitlist" (
CREATE TABLE "shift_pool_waitlist" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "shiftPoolId" TEXT NOT NULL,
    "shiftPoolId" TEXT NOT NULL,
    "driverId" TEXT NOT NULL,
    "driverId" TEXT NOT NULL,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,


    CONSTRAINT "shift_pool_waitlist_pkey" PRIMARY KEY ("id")
    CONSTRAINT "shift_pool_waitlist_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "shift_swap_requests" (
CREATE TABLE "shift_swap_requests" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "driverShiftId" TEXT NOT NULL,
    "driverShiftId" TEXT NOT NULL,
    "offeredByDriverId" TEXT NOT NULL,
    "offeredByDriverId" TEXT NOT NULL,
    "status" "SwapRequestStatus" NOT NULL DEFAULT 'PENDING',
    "status" "SwapRequestStatus" NOT NULL DEFAULT 'PENDING',
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,


    CONSTRAINT "shift_swap_requests_pkey" PRIMARY KEY ("id")
    CONSTRAINT "shift_swap_requests_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "driver_wallet_transactions" (
CREATE TABLE "driver_wallet_transactions" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "driverId" TEXT NOT NULL,
    "driverId" TEXT NOT NULL,
    "orderId" TEXT,
    "orderId" TEXT,
    "driverShiftId" TEXT,
    "driverShiftId" TEXT,
    "type" "WalletTransactionType" NOT NULL,
    "type" "WalletTransactionType" NOT NULL,
    "amount" INTEGER NOT NULL,
    "amount" INTEGER NOT NULL,
    "balanceAfter" INTEGER NOT NULL,
    "balanceAfter" INTEGER NOT NULL,
    "description" TEXT,
    "description" TEXT,
    "referenceId" TEXT,
    "referenceId" TEXT,
    "idempotencyKey" TEXT,
    "idempotencyKey" TEXT,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,


    CONSTRAINT "driver_wallet_transactions_pkey" PRIMARY KEY ("id")
    CONSTRAINT "driver_wallet_transactions_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "driver_statistics" (
CREATE TABLE "driver_statistics" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "driverId" TEXT NOT NULL,
    "driverId" TEXT NOT NULL,
    "period" "StatisticPeriod" NOT NULL,
    "period" "StatisticPeriod" NOT NULL,
    "startDate" DATE NOT NULL,
    "startDate" DATE NOT NULL,
    "endDate" DATE NOT NULL,
    "endDate" DATE NOT NULL,
    "totalOrders" INTEGER NOT NULL DEFAULT 0,
    "totalOrders" INTEGER NOT NULL DEFAULT 0,
    "totalEarnings" INTEGER NOT NULL DEFAULT 0,
    "totalEarnings" INTEGER NOT NULL DEFAULT 0,
    "completedOrders" INTEGER NOT NULL DEFAULT 0,
    "completedOrders" INTEGER NOT NULL DEFAULT 0,
    "cancelledOrders" INTEGER NOT NULL DEFAULT 0,
    "cancelledOrders" INTEGER NOT NULL DEFAULT 0,
    "onlineHours" DOUBLE PRECISION,
    "onlineHours" DOUBLE PRECISION,
    "totalDispatchesReceived" INTEGER NOT NULL DEFAULT 0,
    "totalDispatchesReceived" INTEGER NOT NULL DEFAULT 0,
    "dispatchesAccepted" INTEGER NOT NULL DEFAULT 0,
    "dispatchesAccepted" INTEGER NOT NULL DEFAULT 0,
    "dispatchesRejected" INTEGER NOT NULL DEFAULT 0,
    "dispatchesRejected" INTEGER NOT NULL DEFAULT 0,
    "dispatchesExpired" INTEGER NOT NULL DEFAULT 0,
    "dispatchesExpired" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,


    CONSTRAINT "driver_statistics_pkey" PRIMARY KEY ("id")
    CONSTRAINT "driver_statistics_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "order_dispatches" (
CREATE TABLE "order_dispatches" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "orderId" TEXT NOT NULL,
    "orderId" TEXT NOT NULL,
    "deliveryGroupId" TEXT,
    "deliveryGroupId" TEXT,
    "driverId" TEXT NOT NULL,
    "driverId" TEXT NOT NULL,
    "driverShiftId" TEXT,
    "driverShiftId" TEXT,
    "type" "OrderType" NOT NULL DEFAULT 'STANDARD',
    "type" "OrderType" NOT NULL DEFAULT 'STANDARD',
    "status" "DispatchStatus" NOT NULL DEFAULT 'PENDING',
    "status" "DispatchStatus" NOT NULL DEFAULT 'PENDING',
    "distanceKm" DOUBLE PRECISION,
    "distanceKm" DOUBLE PRECISION,
    "estimatedEarnings" INTEGER,
    "estimatedEarnings" INTEGER,
    "expiresAt" TIMESTAMPTZ(3) NOT NULL,
    "expiresAt" TIMESTAMPTZ(3) NOT NULL,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,


    CONSTRAINT "order_dispatches_pkey" PRIMARY KEY ("id")
    CONSTRAINT "order_dispatches_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "audit_logs" (
CREATE TABLE "audit_logs" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "vendorId" TEXT,
    "vendorId" TEXT,
    "actionType" "AuditActionType" NOT NULL DEFAULT 'OTHER',
    "actionType" "AuditActionType" NOT NULL DEFAULT 'OTHER',
    "action" TEXT NOT NULL,
    "action" TEXT NOT NULL,
    "entityType" TEXT NOT NULL,
    "entityType" TEXT NOT NULL,
    "entityId" TEXT NOT NULL,
    "entityId" TEXT NOT NULL,
    "oldValues" JSONB,
    "oldValues" JSONB,
    "newValues" JSONB,
    "newValues" JSONB,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "sessionId" TEXT,
    "sessionId" TEXT,


    CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id")
    CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "driver_breaks" (
CREATE TABLE "driver_breaks" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "driverId" TEXT NOT NULL,
    "driverId" TEXT NOT NULL,
    "shiftId" TEXT,
    "shiftId" TEXT,
    "reason" "DriverBreakReason" NOT NULL DEFAULT 'REST',
    "reason" "DriverBreakReason" NOT NULL DEFAULT 'REST',
    "note" TEXT,
    "note" TEXT,
    "requestedMinutes" INTEGER,
    "requestedMinutes" INTEGER,
    "status" "DriverBreakStatus" NOT NULL DEFAULT 'PENDING',
    "status" "DriverBreakStatus" NOT NULL DEFAULT 'PENDING',
    "prevStatus" "DriverStatus",
    "prevStatus" "DriverStatus",
    "startedAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "startedAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "endedAt" TIMESTAMPTZ(3),
    "endedAt" TIMESTAMPTZ(3),
    "durationMinutes" INTEGER,
    "durationMinutes" INTEGER,
    "autoEnded" BOOLEAN NOT NULL DEFAULT false,
    "autoEnded" BOOLEAN NOT NULL DEFAULT false,
    "reviewedById" TEXT,
    "reviewedById" TEXT,
    "reviewedAt" TIMESTAMPTZ(3),
    "reviewedAt" TIMESTAMPTZ(3),
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,


    CONSTRAINT "driver_breaks_pkey" PRIMARY KEY ("id")
    CONSTRAINT "driver_breaks_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "promotions" (
CREATE TABLE "promotions" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "titleAr" TEXT,
    "titleAr" TEXT,
    "description" TEXT,
    "description" TEXT,
    "descriptionAr" TEXT,
    "descriptionAr" TEXT,
    "imageUrl" TEXT NOT NULL,
    "imageUrl" TEXT NOT NULL,
    "type" "PromotionType" NOT NULL DEFAULT 'BANNER',
    "type" "PromotionType" NOT NULL DEFAULT 'BANNER',
    "vendorId" TEXT,
    "vendorId" TEXT,
    "productId" TEXT,
    "productId" TEXT,
    "externalUrl" TEXT,
    "externalUrl" TEXT,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "startDate" TIMESTAMPTZ(3),
    "startDate" TIMESTAMPTZ(3),
    "endDate" TIMESTAMPTZ(3),
    "endDate" TIMESTAMPTZ(3),
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,


    CONSTRAINT "promotions_pkey" PRIMARY KEY ("id")
    CONSTRAINT "promotions_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "product_offers" (
CREATE TABLE "product_offers" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "productId" TEXT NOT NULL,
    "productId" TEXT NOT NULL,
    "variantId" TEXT,
    "variantId" TEXT,
    "vendorId" TEXT NOT NULL,
    "vendorId" TEXT NOT NULL,
    "originalPrice" INTEGER NOT NULL,
    "originalPrice" INTEGER NOT NULL,
    "offerPrice" INTEGER NOT NULL,
    "offerPrice" INTEGER NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "startDate" TIMESTAMPTZ(3),
    "startDate" TIMESTAMPTZ(3),
    "endDate" TIMESTAMPTZ(3),
    "endDate" TIMESTAMPTZ(3),
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,


    CONSTRAINT "product_offers_pkey" PRIMARY KEY ("id")
    CONSTRAINT "product_offers_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "mobile_wallets" (
CREATE TABLE "mobile_wallets" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "number" TEXT NOT NULL,
    "number" TEXT NOT NULL,
    "type" "WalletType" NOT NULL,
    "type" "WalletType" NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "isPlatform" BOOLEAN NOT NULL DEFAULT false,
    "isPlatform" BOOLEAN NOT NULL DEFAULT false,
    "driverId" TEXT,
    "driverId" TEXT,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,


    CONSTRAINT "mobile_wallets_pkey" PRIMARY KEY ("id")
    CONSTRAINT "mobile_wallets_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "wallet_top_up_requests" (
CREATE TABLE "wallet_top_up_requests" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "driverId" TEXT NOT NULL,
    "driverId" TEXT NOT NULL,
    "platformWalletId" TEXT NOT NULL,
    "platformWalletId" TEXT NOT NULL,
    "amount" INTEGER NOT NULL,
    "amount" INTEGER NOT NULL,
    "receiptUrl" TEXT NOT NULL,
    "receiptUrl" TEXT NOT NULL,
    "status" "TopUpStatus" NOT NULL DEFAULT 'PENDING',
    "status" "TopUpStatus" NOT NULL DEFAULT 'PENDING',
    "approvedById" TEXT,
    "approvedById" TEXT,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,


    CONSTRAINT "wallet_top_up_requests_pkey" PRIMARY KEY ("id")
    CONSTRAINT "wallet_top_up_requests_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "order_reviews" (
CREATE TABLE "order_reviews" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "orderId" TEXT NOT NULL,
    "orderId" TEXT NOT NULL,
    "customerId" TEXT NOT NULL,
    "customerId" TEXT NOT NULL,
    "vendorId" TEXT,
    "vendorId" TEXT,
    "driverId" TEXT,
    "driverId" TEXT,
    "vendorRating" DOUBLE PRECISION,
    "vendorRating" DOUBLE PRECISION,
    "driverRating" DOUBLE PRECISION,
    "driverRating" DOUBLE PRECISION,
    "comment" TEXT,
    "comment" TEXT,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,


    CONSTRAINT "order_reviews_pkey" PRIMARY KEY ("id")
    CONSTRAINT "order_reviews_pkey" PRIMARY KEY ("id")
);
);


-- CreateTable
-- CreateTable
CREATE TABLE "accounts" (
CREATE TABLE "accounts" (
    "id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "provider" TEXT NOT NULL,
    "provider" TEXT NOT NULL,
    "providerAccountId" TEXT NOT NULL,
    "providerAccountId" TEXT NOT NULL,


    CONSTRAINT "accounts_pkey" PRIMARY KEY ("id")
    CONSTRAINT "accounts_pkey" PRIMARY KEY ("id")
);
);


-- CreateIndex
-- CreateIndex
CREATE INDEX "zones_isActive_idx" ON "zones"("isActive");
CREATE INDEX "zones_isActive_idx" ON "zones"("isActive");


-- CreateIndex
-- CreateIndex
CREATE INDEX "zones_boundary_idx" ON "zones" USING GIST ("boundary");
CREATE INDEX "zones_boundary_idx" ON "zones" USING GIST ("boundary");


-- CreateIndex
-- CreateIndex
CREATE INDEX "users_role_idx" ON "users"("role");
CREATE INDEX "users_role_idx" ON "users"("role");


-- CreateIndex
-- CreateIndex
CREATE INDEX "users_deletedAt_idx" ON "users"("deletedAt");
CREATE INDEX "users_deletedAt_idx" ON "users"("deletedAt");


-- CreateIndex
-- CreateIndex
CREATE UNIQUE INDEX "devices_token_key" ON "devices"("token");
CREATE UNIQUE INDEX "devices_token_key" ON "devices"("token");


-- CreateIndex
-- CreateIndex
CREATE INDEX "devices_userId_platform_idx" ON "devices"("userId", "platform");
CREATE INDEX "devices_userId_platform_idx" ON "devices"("userId", "platform");


-- CreateIndex
-- CreateIndex
CREATE INDEX "devices_lastActive_idx" ON "devices"("lastActive");
CREATE INDEX "devices_lastActive_idx" ON "devices"("lastActive");


-- CreateIndex
-- CreateIndex
CREATE INDEX "sessions_userId_idx" ON "sessions"("userId");
CREATE INDEX "sessions_userId_idx" ON "sessions"("userId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "sessions_expiresAt_idx" ON "sessions"("expiresAt");
CREATE INDEX "sessions_expiresAt_idx" ON "sessions"("expiresAt");


-- CreateIndex
-- CreateIndex
CREATE INDEX "notifications_userId_isRead_idx" ON "notifications"("userId", "isRead");
CREATE INDEX "notifications_userId_isRead_idx" ON "notifications"("userId", "isRead");


-- CreateIndex
-- CreateIndex
CREATE INDEX "notifications_userId_createdAt_idx" ON "notifications"("userId", "createdAt");
CREATE INDEX "notifications_userId_createdAt_idx" ON "notifications"("userId", "createdAt");


-- CreateIndex
-- CreateIndex
CREATE INDEX "notifications_userId_type_idx" ON "notifications"("userId", "type");
CREATE INDEX "notifications_userId_type_idx" ON "notifications"("userId", "type");


-- CreateIndex
-- CreateIndex
CREATE INDEX "notifications_createdAt_idx" ON "notifications"("createdAt");
CREATE INDEX "notifications_createdAt_idx" ON "notifications"("createdAt");


-- CreateIndex
-- CreateIndex
CREATE UNIQUE INDEX "notification_settings_userId_key" ON "notification_settings"("userId");
CREATE UNIQUE INDEX "notification_settings_userId_key" ON "notification_settings"("userId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "conversations_orderId_idx" ON "conversations"("orderId");
CREATE INDEX "conversations_orderId_idx" ON "conversations"("orderId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "conversations_vendorId_idx" ON "conversations"("vendorId");
CREATE INDEX "conversations_vendorId_idx" ON "conversations"("vendorId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "conversations_creatorId_idx" ON "conversations"("creatorId");
CREATE INDEX "conversations_creatorId_idx" ON "conversations"("creatorId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "conversations_createdAt_idx" ON "conversations"("createdAt");
CREATE INDEX "conversations_createdAt_idx" ON "conversations"("createdAt");


-- CreateIndex
-- CreateIndex
CREATE INDEX "conversations_updatedAt_idx" ON "conversations"("updatedAt");
CREATE INDEX "conversations_updatedAt_idx" ON "conversations"("updatedAt");


-- CreateIndex
-- CreateIndex
CREATE INDEX "conversations_deletedAt_idx" ON "conversations"("deletedAt");
CREATE INDEX "conversations_deletedAt_idx" ON "conversations"("deletedAt");


-- CreateIndex
-- CreateIndex
CREATE INDEX "conversation_participants_userId_idx" ON "conversation_participants"("userId");
CREATE INDEX "conversation_participants_userId_idx" ON "conversation_participants"("userId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "conversation_participants_lastReadAt_idx" ON "conversation_participants"("lastReadAt");
CREATE INDEX "conversation_participants_lastReadAt_idx" ON "conversation_participants"("lastReadAt");


-- CreateIndex
-- CreateIndex
CREATE INDEX "messages_conversationId_createdAt_idx" ON "messages"("conversationId", "createdAt");
CREATE INDEX "messages_conversationId_createdAt_idx" ON "messages"("conversationId", "createdAt");


-- CreateIndex
-- CreateIndex
CREATE INDEX "messages_senderId_idx" ON "messages"("senderId");
CREATE INDEX "messages_senderId_idx" ON "messages"("senderId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "messages_replyToId_idx" ON "messages"("replyToId");
CREATE INDEX "messages_replyToId_idx" ON "messages"("replyToId");


-- CreateIndex
-- CreateIndex
CREATE UNIQUE INDEX "support_tickets_ticketNumber_key" ON "support_tickets"("ticketNumber");
CREATE UNIQUE INDEX "support_tickets_ticketNumber_key" ON "support_tickets"("ticketNumber");


-- CreateIndex
-- CreateIndex
CREATE UNIQUE INDEX "support_tickets_conversationId_key" ON "support_tickets"("conversationId");
CREATE UNIQUE INDEX "support_tickets_conversationId_key" ON "support_tickets"("conversationId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "support_tickets_creatorId_idx" ON "support_tickets"("creatorId");
CREATE INDEX "support_tickets_creatorId_idx" ON "support_tickets"("creatorId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "support_tickets_assigneeId_idx" ON "support_tickets"("assigneeId");
CREATE INDEX "support_tickets_assigneeId_idx" ON "support_tickets"("assigneeId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "support_tickets_vendorId_idx" ON "support_tickets"("vendorId");
CREATE INDEX "support_tickets_vendorId_idx" ON "support_tickets"("vendorId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "support_tickets_status_idx" ON "support_tickets"("status");
CREATE INDEX "support_tickets_status_idx" ON "support_tickets"("status");


-- CreateIndex
-- CreateIndex
CREATE INDEX "support_tickets_orderId_idx" ON "support_tickets"("orderId");
CREATE INDEX "support_tickets_orderId_idx" ON "support_tickets"("orderId");


-- CreateIndex
-- CreateIndex
CREATE UNIQUE INDEX "customers_userId_key" ON "customers"("userId");
CREATE UNIQUE INDEX "customers_userId_key" ON "customers"("userId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "customers_createdAt_idx" ON "customers"("createdAt");
CREATE INDEX "customers_createdAt_idx" ON "customers"("createdAt");


-- CreateIndex
-- CreateIndex
CREATE INDEX "customers_deletedAt_idx" ON "customers"("deletedAt");
CREATE INDEX "customers_deletedAt_idx" ON "customers"("deletedAt");


-- CreateIndex
-- CreateIndex
CREATE INDEX "customer_coin_transactions_customerId_idx" ON "customer_coin_transactions"("customerId");
CREATE INDEX "customer_coin_transactions_customerId_idx" ON "customer_coin_transactions"("customerId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "customer_coin_transactions_orderId_idx" ON "customer_coin_transactions"("orderId");
CREATE INDEX "customer_coin_transactions_orderId_idx" ON "customer_coin_transactions"("orderId");


-- CreateIndex
-- CreateIndex
CREATE UNIQUE INDEX "customer_coin_transactions_orderId_type_key" ON "customer_coin_transactions"("orderId", "type");
CREATE UNIQUE INDEX "customer_coin_transactions_orderId_type_key" ON "customer_coin_transactions"("orderId", "type");


-- CreateIndex
-- CreateIndex
CREATE UNIQUE INDEX "favorite_vendors_customerId_vendorId_key" ON "favorite_vendors"("customerId", "vendorId");
CREATE UNIQUE INDEX "favorite_vendors_customerId_vendorId_key" ON "favorite_vendors"("customerId", "vendorId");


-- CreateIndex
-- CreateIndex
CREATE UNIQUE INDEX "favorite_products_customerId_productId_key" ON "favorite_products"("customerId", "productId");
CREATE UNIQUE INDEX "favorite_products_customerId_productId_key" ON "favorite_products"("customerId", "productId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "addresses_customerId_idx" ON "addresses"("customerId");
CREATE INDEX "addresses_customerId_idx" ON "addresses"("customerId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "addresses_location_idx" ON "addresses" USING GIST ("location");
CREATE INDEX "addresses_location_idx" ON "addresses" USING GIST ("location");


-- CreateIndex
-- CreateIndex
CREATE UNIQUE INDEX "vendor_verticals_slug_key" ON "vendor_verticals"("slug");
CREATE UNIQUE INDEX "vendor_verticals_slug_key" ON "vendor_verticals"("slug");


-- CreateIndex
-- CreateIndex
CREATE INDEX "vendor_verticals_isActive_sortOrder_idx" ON "vendor_verticals"("isActive", "sortOrder");
CREATE INDEX "vendor_verticals_isActive_sortOrder_idx" ON "vendor_verticals"("isActive", "sortOrder");


-- CreateIndex
-- CreateIndex
CREATE UNIQUE INDEX "vendors_slug_key" ON "vendors"("slug");
CREATE UNIQUE INDEX "vendors_slug_key" ON "vendors"("slug");


-- CreateIndex
-- CreateIndex
CREATE INDEX "vendors_createdAt_idx" ON "vendors"("createdAt");
CREATE INDEX "vendors_createdAt_idx" ON "vendors"("createdAt");


-- CreateIndex
-- CreateIndex
CREATE INDEX "vendors_status_idx" ON "vendors"("status");
CREATE INDEX "vendors_status_idx" ON "vendors"("status");


-- CreateIndex
-- CreateIndex
CREATE INDEX "vendors_verticalId_idx" ON "vendors"("verticalId");
CREATE INDEX "vendors_verticalId_idx" ON "vendors"("verticalId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "vendors_deletedAt_idx" ON "vendors"("deletedAt");
CREATE INDEX "vendors_deletedAt_idx" ON "vendors"("deletedAt");


-- CreateIndex
-- CreateIndex
CREATE INDEX "vendor_members_userId_idx" ON "vendor_members"("userId");
CREATE INDEX "vendor_members_userId_idx" ON "vendor_members"("userId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "vendor_members_branchId_idx" ON "vendor_members"("branchId");
CREATE INDEX "vendor_members_branchId_idx" ON "vendor_members"("branchId");


-- CreateIndex
-- CreateIndex
CREATE UNIQUE INDEX "vendor_members_vendorId_userId_key" ON "vendor_members"("vendorId", "userId");
CREATE UNIQUE INDEX "vendor_members_vendorId_userId_key" ON "vendor_members"("vendorId", "userId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "vendor_branches_zoneId_idx" ON "vendor_branches"("zoneId");
CREATE INDEX "vendor_branches_zoneId_idx" ON "vendor_branches"("zoneId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "vendor_branches_vendorId_isOpen_idx" ON "vendor_branches"("vendorId", "isOpen");
CREATE INDEX "vendor_branches_vendorId_isOpen_idx" ON "vendor_branches"("vendorId", "isOpen");


-- CreateIndex
-- CreateIndex
CREATE INDEX "vendor_branches_location_idx" ON "vendor_branches" USING GIST ("location");
CREATE INDEX "vendor_branches_location_idx" ON "vendor_branches" USING GIST ("location");


-- CreateIndex
-- CreateIndex
CREATE INDEX "vendor_wallet_transactions_vendorId_idx" ON "vendor_wallet_transactions"("vendorId");
CREATE INDEX "vendor_wallet_transactions_vendorId_idx" ON "vendor_wallet_transactions"("vendorId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "vendor_wallet_transactions_orderId_idx" ON "vendor_wallet_transactions"("orderId");
CREATE INDEX "vendor_wallet_transactions_orderId_idx" ON "vendor_wallet_transactions"("orderId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "vendor_wallet_transactions_createdAt_idx" ON "vendor_wallet_transactions"("createdAt");
CREATE INDEX "vendor_wallet_transactions_createdAt_idx" ON "vendor_wallet_transactions"("createdAt");


-- CreateIndex
-- CreateIndex
CREATE UNIQUE INDEX "vendor_wallet_transactions_orderId_type_vendorId_key" ON "vendor_wallet_transactions"("orderId", "type", "vendorId");
CREATE UNIQUE INDEX "vendor_wallet_transactions_orderId_type_vendorId_key" ON "vendor_wallet_transactions"("orderId", "type", "vendorId");


-- CreateIndex
-- CreateIndex
CREATE UNIQUE INDEX "vendor_wallet_transactions_vendorId_idempotencyKey_key" ON "vendor_wallet_transactions"("vendorId", "idempotencyKey");
CREATE UNIQUE INDEX "vendor_wallet_transactions_vendorId_idempotencyKey_key" ON "vendor_wallet_transactions"("vendorId", "idempotencyKey");


-- CreateIndex
-- CreateIndex
CREATE INDEX "vendor_statistics_startDate_endDate_idx" ON "vendor_statistics"("startDate", "endDate");
CREATE INDEX "vendor_statistics_startDate_endDate_idx" ON "vendor_statistics"("startDate", "endDate");


-- CreateIndex
-- CreateIndex
CREATE UNIQUE INDEX "vendor_statistics_vendorId_period_startDate_key" ON "vendor_statistics"("vendorId", "period", "startDate");
CREATE UNIQUE INDEX "vendor_statistics_vendorId_period_startDate_key" ON "vendor_statistics"("vendorId", "period", "startDate");


-- CreateIndex
-- CreateIndex
CREATE INDEX "app_statistics_startDate_endDate_idx" ON "app_statistics"("startDate", "endDate");
CREATE INDEX "app_statistics_startDate_endDate_idx" ON "app_statistics"("startDate", "endDate");


-- CreateIndex
-- CreateIndex
CREATE UNIQUE INDEX "app_statistics_period_startDate_key" ON "app_statistics"("period", "startDate");
CREATE UNIQUE INDEX "app_statistics_period_startDate_key" ON "app_statistics"("period", "startDate");


-- CreateIndex
-- CreateIndex
CREATE INDEX "stat_processing_markers_createdAt_idx" ON "stat_processing_markers"("createdAt");
CREATE INDEX "stat_processing_markers_createdAt_idx" ON "stat_processing_markers"("createdAt");


-- CreateIndex
-- CreateIndex
CREATE INDEX "menu_categories_vendorId_isActive_idx" ON "menu_categories"("vendorId", "isActive");
CREATE INDEX "menu_categories_vendorId_isActive_idx" ON "menu_categories"("vendorId", "isActive");


-- CreateIndex
-- CreateIndex
CREATE UNIQUE INDEX "products_sku_key" ON "products"("sku");
CREATE UNIQUE INDEX "products_sku_key" ON "products"("sku");


-- CreateIndex
-- CreateIndex
CREATE INDEX "products_vendorId_isActive_isFeatured_idx" ON "products"("vendorId", "isActive", "isFeatured");
CREATE INDEX "products_vendorId_isActive_isFeatured_idx" ON "products"("vendorId", "isActive", "isFeatured");


-- CreateIndex
-- CreateIndex
CREATE INDEX "products_categoryId_idx" ON "products"("categoryId");
CREATE INDEX "products_categoryId_idx" ON "products"("categoryId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "products_deletedAt_idx" ON "products"("deletedAt");
CREATE INDEX "products_deletedAt_idx" ON "products"("deletedAt");


-- CreateIndex
-- CreateIndex
CREATE UNIQUE INDEX "product_variants_sku_key" ON "product_variants"("sku");
CREATE UNIQUE INDEX "product_variants_sku_key" ON "product_variants"("sku");


-- CreateIndex
-- CreateIndex
CREATE INDEX "product_variants_productId_isActive_idx" ON "product_variants"("productId", "isActive");
CREATE INDEX "product_variants_productId_isActive_idx" ON "product_variants"("productId", "isActive");


-- CreateIndex
-- CreateIndex
CREATE INDEX "product_option_groups_productId_idx" ON "product_option_groups"("productId");
CREATE INDEX "product_option_groups_productId_idx" ON "product_option_groups"("productId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "product_option_groups_variantId_idx" ON "product_option_groups"("variantId");
CREATE INDEX "product_option_groups_variantId_idx" ON "product_option_groups"("variantId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "product_options_groupId_idx" ON "product_options"("groupId");
CREATE INDEX "product_options_groupId_idx" ON "product_options"("groupId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "carts_customerId_idx" ON "carts"("customerId");
CREATE INDEX "carts_customerId_idx" ON "carts"("customerId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "carts_updatedAt_idx" ON "carts"("updatedAt");
CREATE INDEX "carts_updatedAt_idx" ON "carts"("updatedAt");


-- CreateIndex
-- CreateIndex
CREATE UNIQUE INDEX "carts_customerId_vendorId_key" ON "carts"("customerId", "vendorId");
CREATE UNIQUE INDEX "carts_customerId_vendorId_key" ON "carts"("customerId", "vendorId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "cart_item_options_cartItemId_idx" ON "cart_item_options"("cartItemId");
CREATE INDEX "cart_item_options_cartItemId_idx" ON "cart_item_options"("cartItemId");


-- CreateIndex
-- CreateIndex
CREATE UNIQUE INDEX "orders_orderNumber_key" ON "orders"("orderNumber");
CREATE UNIQUE INDEX "orders_orderNumber_key" ON "orders"("orderNumber");


-- CreateIndex
-- CreateIndex
CREATE UNIQUE INDEX "orders_clientOrderKey_key" ON "orders"("clientOrderKey");
CREATE UNIQUE INDEX "orders_clientOrderKey_key" ON "orders"("clientOrderKey");


-- CreateIndex
-- CreateIndex
CREATE INDEX "orders_customerId_idx" ON "orders"("customerId");
CREATE INDEX "orders_customerId_idx" ON "orders"("customerId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "orders_zoneId_idx" ON "orders"("zoneId");
CREATE INDEX "orders_zoneId_idx" ON "orders"("zoneId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "orders_vendorId_status_idx" ON "orders"("vendorId", "status");
CREATE INDEX "orders_vendorId_status_idx" ON "orders"("vendorId", "status");


-- CreateIndex
-- CreateIndex
CREATE INDEX "orders_driverId_idx" ON "orders"("driverId");
CREATE INDEX "orders_driverId_idx" ON "orders"("driverId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "orders_status_idx" ON "orders"("status");
CREATE INDEX "orders_status_idx" ON "orders"("status");


-- CreateIndex
-- CreateIndex
CREATE INDEX "orders_deletedAt_idx" ON "orders"("deletedAt");
CREATE INDEX "orders_deletedAt_idx" ON "orders"("deletedAt");


-- CreateIndex
-- CreateIndex
CREATE INDEX "orders_createdAt_idx" ON "orders"("createdAt");
CREATE INDEX "orders_createdAt_idx" ON "orders"("createdAt");


-- CreateIndex
-- CreateIndex
CREATE INDEX "orders_status_createdAt_idx" ON "orders"("status", "createdAt");
CREATE INDEX "orders_status_createdAt_idx" ON "orders"("status", "createdAt");


-- CreateIndex
-- CreateIndex
CREATE INDEX "orders_status_updatedAt_idx" ON "orders"("status", "updatedAt");
CREATE INDEX "orders_status_updatedAt_idx" ON "orders"("status", "updatedAt");


-- CreateIndex
-- CreateIndex
CREATE INDEX "orders_customerId_createdAt_idx" ON "orders"("customerId", "createdAt");
CREATE INDEX "orders_customerId_createdAt_idx" ON "orders"("customerId", "createdAt");


-- CreateIndex
-- CreateIndex
CREATE INDEX "orders_vendorId_createdAt_idx" ON "orders"("vendorId", "createdAt");
CREATE INDEX "orders_vendorId_createdAt_idx" ON "orders"("vendorId", "createdAt");


-- CreateIndex
-- CreateIndex
CREATE INDEX "orders_driverId_createdAt_idx" ON "orders"("driverId", "createdAt");
CREATE INDEX "orders_driverId_createdAt_idx" ON "orders"("driverId", "createdAt");


-- CreateIndex
-- CreateIndex
CREATE INDEX "orders_customerId_status_idx" ON "orders"("customerId", "status");
CREATE INDEX "orders_customerId_status_idx" ON "orders"("customerId", "status");


-- CreateIndex
-- CreateIndex
CREATE INDEX "orders_deliveryLocation_idx" ON "orders" USING GIST ("deliveryLocation");
CREATE INDEX "orders_deliveryLocation_idx" ON "orders" USING GIST ("deliveryLocation");


-- CreateIndex
-- CreateIndex
CREATE INDEX "order_status_events_orderId_createdAt_idx" ON "order_status_events"("orderId", "createdAt");
CREATE INDEX "order_status_events_orderId_createdAt_idx" ON "order_status_events"("orderId", "createdAt");


-- CreateIndex
-- CreateIndex
CREATE INDEX "order_items_orderId_idx" ON "order_items"("orderId");
CREATE INDEX "order_items_orderId_idx" ON "order_items"("orderId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "order_items_fulfillmentId_idx" ON "order_items"("fulfillmentId");
CREATE INDEX "order_items_fulfillmentId_idx" ON "order_items"("fulfillmentId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "order_item_options_orderItemId_idx" ON "order_item_options"("orderItemId");
CREATE INDEX "order_item_options_orderItemId_idx" ON "order_item_options"("orderItemId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "order_vendor_fulfillments_orderId_idx" ON "order_vendor_fulfillments"("orderId");
CREATE INDEX "order_vendor_fulfillments_orderId_idx" ON "order_vendor_fulfillments"("orderId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "order_vendor_fulfillments_vendorId_status_idx" ON "order_vendor_fulfillments"("vendorId", "status");
CREATE INDEX "order_vendor_fulfillments_vendorId_status_idx" ON "order_vendor_fulfillments"("vendorId", "status");


-- CreateIndex
-- CreateIndex
CREATE INDEX "order_vendor_fulfillments_status_createdAt_idx" ON "order_vendor_fulfillments"("status", "createdAt");
CREATE INDEX "order_vendor_fulfillments_status_createdAt_idx" ON "order_vendor_fulfillments"("status", "createdAt");


-- CreateIndex
-- CreateIndex
CREATE INDEX "order_delivery_groups_orderId_idx" ON "order_delivery_groups"("orderId");
CREATE INDEX "order_delivery_groups_orderId_idx" ON "order_delivery_groups"("orderId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "order_delivery_groups_primaryDriverId_idx" ON "order_delivery_groups"("primaryDriverId");
CREATE INDEX "order_delivery_groups_primaryDriverId_idx" ON "order_delivery_groups"("primaryDriverId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "order_delivery_groups_status_idx" ON "order_delivery_groups"("status");
CREATE INDEX "order_delivery_groups_status_idx" ON "order_delivery_groups"("status");


-- CreateIndex
-- CreateIndex
CREATE UNIQUE INDEX "order_delivery_groups_orderId_sequence_key" ON "order_delivery_groups"("orderId", "sequence");
CREATE UNIQUE INDEX "order_delivery_groups_orderId_sequence_key" ON "order_delivery_groups"("orderId", "sequence");


-- CreateIndex
-- CreateIndex
CREATE UNIQUE INDEX "order_delivery_group_items_fulfillmentId_key" ON "order_delivery_group_items"("fulfillmentId");
CREATE UNIQUE INDEX "order_delivery_group_items_fulfillmentId_key" ON "order_delivery_group_items"("fulfillmentId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "driver_assist_requests_orderId_idx" ON "driver_assist_requests"("orderId");
CREATE INDEX "driver_assist_requests_orderId_idx" ON "driver_assist_requests"("orderId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "driver_assist_requests_driverId_createdAt_idx" ON "driver_assist_requests"("driverId", "createdAt");
CREATE INDEX "driver_assist_requests_driverId_createdAt_idx" ON "driver_assist_requests"("driverId", "createdAt");


-- CreateIndex
-- CreateIndex
CREATE INDEX "driver_assist_requests_status_createdAt_idx" ON "driver_assist_requests"("status", "createdAt");
CREATE INDEX "driver_assist_requests_status_createdAt_idx" ON "driver_assist_requests"("status", "createdAt");


-- CreateIndex
-- CreateIndex
CREATE INDEX "driver_assist_requests_deliveryGroupId_idx" ON "driver_assist_requests"("deliveryGroupId");
CREATE INDEX "driver_assist_requests_deliveryGroupId_idx" ON "driver_assist_requests"("deliveryGroupId");


-- CreateIndex
-- CreateIndex
CREATE UNIQUE INDEX "drivers_userId_key" ON "drivers"("userId");
CREATE UNIQUE INDEX "drivers_userId_key" ON "drivers"("userId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "drivers_status_idx" ON "drivers"("status");
CREATE INDEX "drivers_status_idx" ON "drivers"("status");


-- CreateIndex
-- CreateIndex
CREATE INDEX "drivers_createdAt_idx" ON "drivers"("createdAt");
CREATE INDEX "drivers_createdAt_idx" ON "drivers"("createdAt");


-- CreateIndex
-- CreateIndex
CREATE INDEX "drivers_deletedAt_idx" ON "drivers"("deletedAt");
CREATE INDEX "drivers_deletedAt_idx" ON "drivers"("deletedAt");


-- CreateIndex
-- CreateIndex
CREATE INDEX "driver_shifts_shiftPoolId_idx" ON "driver_shifts"("shiftPoolId");
CREATE INDEX "driver_shifts_shiftPoolId_idx" ON "driver_shifts"("shiftPoolId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "driver_shifts_zoneId_idx" ON "driver_shifts"("zoneId");
CREATE INDEX "driver_shifts_zoneId_idx" ON "driver_shifts"("zoneId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "driver_shifts_driverId_status_idx" ON "driver_shifts"("driverId", "status");
CREATE INDEX "driver_shifts_driverId_status_idx" ON "driver_shifts"("driverId", "status");


-- CreateIndex
-- CreateIndex
CREATE INDEX "driver_shifts_shiftDate_idx" ON "driver_shifts"("shiftDate");
CREATE INDEX "driver_shifts_shiftDate_idx" ON "driver_shifts"("shiftDate");


-- CreateIndex
-- CreateIndex
CREATE INDEX "driver_shifts_status_idx" ON "driver_shifts"("status");
CREATE INDEX "driver_shifts_status_idx" ON "driver_shifts"("status");


-- CreateIndex
-- CreateIndex
CREATE INDEX "driver_shifts_startingLocation_idx" ON "driver_shifts" USING GIST ("startingLocation");
CREATE INDEX "driver_shifts_startingLocation_idx" ON "driver_shifts" USING GIST ("startingLocation");


-- CreateIndex
-- CreateIndex
CREATE INDEX "driver_shifts_endingLocation_idx" ON "driver_shifts" USING GIST ("endingLocation");
CREATE INDEX "driver_shifts_endingLocation_idx" ON "driver_shifts" USING GIST ("endingLocation");


-- CreateIndex
-- CreateIndex
CREATE INDEX "shift_pools_shiftDate_idx" ON "shift_pools"("shiftDate");
CREATE INDEX "shift_pools_shiftDate_idx" ON "shift_pools"("shiftDate");


-- CreateIndex
-- CreateIndex
CREATE INDEX "shift_pools_zoneId_idx" ON "shift_pools"("zoneId");
CREATE INDEX "shift_pools_zoneId_idx" ON "shift_pools"("zoneId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "shift_pools_batchId_idx" ON "shift_pools"("batchId");
CREATE INDEX "shift_pools_batchId_idx" ON "shift_pools"("batchId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "shift_pool_waitlist_shiftPoolId_createdAt_idx" ON "shift_pool_waitlist"("shiftPoolId", "createdAt");
CREATE INDEX "shift_pool_waitlist_shiftPoolId_createdAt_idx" ON "shift_pool_waitlist"("shiftPoolId", "createdAt");


-- CreateIndex
-- CreateIndex
CREATE UNIQUE INDEX "shift_pool_waitlist_shiftPoolId_driverId_key" ON "shift_pool_waitlist"("shiftPoolId", "driverId");
CREATE UNIQUE INDEX "shift_pool_waitlist_shiftPoolId_driverId_key" ON "shift_pool_waitlist"("shiftPoolId", "driverId");


-- CreateIndex
-- CreateIndex
CREATE UNIQUE INDEX "shift_swap_requests_driverShiftId_key" ON "shift_swap_requests"("driverShiftId");
CREATE UNIQUE INDEX "shift_swap_requests_driverShiftId_key" ON "shift_swap_requests"("driverShiftId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "shift_swap_requests_status_idx" ON "shift_swap_requests"("status");
CREATE INDEX "shift_swap_requests_status_idx" ON "shift_swap_requests"("status");


-- CreateIndex
-- CreateIndex
CREATE INDEX "shift_swap_requests_offeredByDriverId_idx" ON "shift_swap_requests"("offeredByDriverId");
CREATE INDEX "shift_swap_requests_offeredByDriverId_idx" ON "shift_swap_requests"("offeredByDriverId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "driver_wallet_transactions_driverId_idx" ON "driver_wallet_transactions"("driverId");
CREATE INDEX "driver_wallet_transactions_driverId_idx" ON "driver_wallet_transactions"("driverId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "driver_wallet_transactions_orderId_idx" ON "driver_wallet_transactions"("orderId");
CREATE INDEX "driver_wallet_transactions_orderId_idx" ON "driver_wallet_transactions"("orderId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "driver_wallet_transactions_createdAt_idx" ON "driver_wallet_transactions"("createdAt");
CREATE INDEX "driver_wallet_transactions_createdAt_idx" ON "driver_wallet_transactions"("createdAt");


-- CreateIndex
-- CreateIndex
CREATE INDEX "driver_wallet_transactions_driverShiftId_idx" ON "driver_wallet_transactions"("driverShiftId");
CREATE INDEX "driver_wallet_transactions_driverShiftId_idx" ON "driver_wallet_transactions"("driverShiftId");


-- CreateIndex
-- CreateIndex
CREATE UNIQUE INDEX "driver_wallet_transactions_orderId_type_driverId_key" ON "driver_wallet_transactions"("orderId", "type", "driverId");
CREATE UNIQUE INDEX "driver_wallet_transactions_orderId_type_driverId_key" ON "driver_wallet_transactions"("orderId", "type", "driverId");


-- CreateIndex
-- CreateIndex
CREATE UNIQUE INDEX "driver_wallet_transactions_driverId_idempotencyKey_key" ON "driver_wallet_transactions"("driverId", "idempotencyKey");
CREATE UNIQUE INDEX "driver_wallet_transactions_driverId_idempotencyKey_key" ON "driver_wallet_transactions"("driverId", "idempotencyKey");


-- CreateIndex
-- CreateIndex
CREATE INDEX "driver_statistics_startDate_endDate_idx" ON "driver_statistics"("startDate", "endDate");
CREATE INDEX "driver_statistics_startDate_endDate_idx" ON "driver_statistics"("startDate", "endDate");


-- CreateIndex
-- CreateIndex
CREATE UNIQUE INDEX "driver_statistics_driverId_period_startDate_key" ON "driver_statistics"("driverId", "period", "startDate");
CREATE UNIQUE INDEX "driver_statistics_driverId_period_startDate_key" ON "driver_statistics"("driverId", "period", "startDate");


-- CreateIndex
-- CreateIndex
CREATE INDEX "order_dispatches_orderId_idx" ON "order_dispatches"("orderId");
CREATE INDEX "order_dispatches_orderId_idx" ON "order_dispatches"("orderId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "order_dispatches_deliveryGroupId_idx" ON "order_dispatches"("deliveryGroupId");
CREATE INDEX "order_dispatches_deliveryGroupId_idx" ON "order_dispatches"("deliveryGroupId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "order_dispatches_driverId_idx" ON "order_dispatches"("driverId");
CREATE INDEX "order_dispatches_driverId_idx" ON "order_dispatches"("driverId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "order_dispatches_driverShiftId_idx" ON "order_dispatches"("driverShiftId");
CREATE INDEX "order_dispatches_driverShiftId_idx" ON "order_dispatches"("driverShiftId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "order_dispatches_status_idx" ON "order_dispatches"("status");
CREATE INDEX "order_dispatches_status_idx" ON "order_dispatches"("status");


-- CreateIndex
-- CreateIndex
CREATE INDEX "order_dispatches_createdAt_idx" ON "order_dispatches"("createdAt");
CREATE INDEX "order_dispatches_createdAt_idx" ON "order_dispatches"("createdAt");


-- CreateIndex
-- CreateIndex
CREATE INDEX "order_dispatches_driverId_status_idx" ON "order_dispatches"("driverId", "status");
CREATE INDEX "order_dispatches_driverId_status_idx" ON "order_dispatches"("driverId", "status");


-- CreateIndex
-- CreateIndex
CREATE INDEX "audit_logs_userId_idx" ON "audit_logs"("userId");
CREATE INDEX "audit_logs_userId_idx" ON "audit_logs"("userId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "audit_logs_vendorId_idx" ON "audit_logs"("vendorId");
CREATE INDEX "audit_logs_vendorId_idx" ON "audit_logs"("vendorId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "audit_logs_actionType_idx" ON "audit_logs"("actionType");
CREATE INDEX "audit_logs_actionType_idx" ON "audit_logs"("actionType");


-- CreateIndex
-- CreateIndex
CREATE INDEX "audit_logs_entityType_entityId_idx" ON "audit_logs"("entityType", "entityId");
CREATE INDEX "audit_logs_entityType_entityId_idx" ON "audit_logs"("entityType", "entityId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "audit_logs_sessionId_idx" ON "audit_logs"("sessionId");
CREATE INDEX "audit_logs_sessionId_idx" ON "audit_logs"("sessionId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "audit_logs_createdAt_idx" ON "audit_logs"("createdAt");
CREATE INDEX "audit_logs_createdAt_idx" ON "audit_logs"("createdAt");


-- CreateIndex
-- CreateIndex
CREATE INDEX "driver_breaks_driverId_createdAt_idx" ON "driver_breaks"("driverId", "createdAt");
CREATE INDEX "driver_breaks_driverId_createdAt_idx" ON "driver_breaks"("driverId", "createdAt");


-- CreateIndex
-- CreateIndex
CREATE INDEX "driver_breaks_shiftId_idx" ON "driver_breaks"("shiftId");
CREATE INDEX "driver_breaks_shiftId_idx" ON "driver_breaks"("shiftId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "driver_breaks_status_idx" ON "driver_breaks"("status");
CREATE INDEX "driver_breaks_status_idx" ON "driver_breaks"("status");


-- CreateIndex
-- CreateIndex
CREATE INDEX "promotions_isActive_sortOrder_idx" ON "promotions"("isActive", "sortOrder");
CREATE INDEX "promotions_isActive_sortOrder_idx" ON "promotions"("isActive", "sortOrder");


-- CreateIndex
-- CreateIndex
CREATE INDEX "product_offers_isActive_sortOrder_idx" ON "product_offers"("isActive", "sortOrder");
CREATE INDEX "product_offers_isActive_sortOrder_idx" ON "product_offers"("isActive", "sortOrder");


-- CreateIndex
-- CreateIndex
CREATE INDEX "product_offers_productId_idx" ON "product_offers"("productId");
CREATE INDEX "product_offers_productId_idx" ON "product_offers"("productId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "product_offers_variantId_idx" ON "product_offers"("variantId");
CREATE INDEX "product_offers_variantId_idx" ON "product_offers"("variantId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "mobile_wallets_driverId_idx" ON "mobile_wallets"("driverId");
CREATE INDEX "mobile_wallets_driverId_idx" ON "mobile_wallets"("driverId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "wallet_top_up_requests_driverId_idx" ON "wallet_top_up_requests"("driverId");
CREATE INDEX "wallet_top_up_requests_driverId_idx" ON "wallet_top_up_requests"("driverId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "wallet_top_up_requests_platformWalletId_idx" ON "wallet_top_up_requests"("platformWalletId");
CREATE INDEX "wallet_top_up_requests_platformWalletId_idx" ON "wallet_top_up_requests"("platformWalletId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "wallet_top_up_requests_approvedById_idx" ON "wallet_top_up_requests"("approvedById");
CREATE INDEX "wallet_top_up_requests_approvedById_idx" ON "wallet_top_up_requests"("approvedById");


-- CreateIndex
-- CreateIndex
CREATE UNIQUE INDEX "order_reviews_orderId_key" ON "order_reviews"("orderId");
CREATE UNIQUE INDEX "order_reviews_orderId_key" ON "order_reviews"("orderId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "order_reviews_vendorId_idx" ON "order_reviews"("vendorId");
CREATE INDEX "order_reviews_vendorId_idx" ON "order_reviews"("vendorId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "order_reviews_driverId_idx" ON "order_reviews"("driverId");
CREATE INDEX "order_reviews_driverId_idx" ON "order_reviews"("driverId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "order_reviews_customerId_idx" ON "order_reviews"("customerId");
CREATE INDEX "order_reviews_customerId_idx" ON "order_reviews"("customerId");


-- CreateIndex
-- CreateIndex
CREATE INDEX "accounts_userId_idx" ON "accounts"("userId");
CREATE INDEX "accounts_userId_idx" ON "accounts"("userId");


-- CreateIndex
-- CreateIndex
CREATE UNIQUE INDEX "accounts_provider_providerAccountId_key" ON "accounts"("provider", "providerAccountId");
CREATE UNIQUE INDEX "accounts_provider_providerAccountId_key" ON "accounts"("provider", "providerAccountId");


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "devices" ADD CONSTRAINT "devices_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "devices" ADD CONSTRAINT "devices_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "sessions" ADD CONSTRAINT "sessions_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "sessions" ADD CONSTRAINT "sessions_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "notification_settings" ADD CONSTRAINT "notification_settings_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "notification_settings" ADD CONSTRAINT "notification_settings_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "conversations" ADD CONSTRAINT "conversations_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "orders"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "conversations" ADD CONSTRAINT "conversations_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "orders"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "conversations" ADD CONSTRAINT "conversations_creatorId_fkey" FOREIGN KEY ("creatorId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "conversations" ADD CONSTRAINT "conversations_creatorId_fkey" FOREIGN KEY ("creatorId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "conversations" ADD CONSTRAINT "conversations_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "vendors"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "conversations" ADD CONSTRAINT "conversations_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "vendors"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "conversation_participants" ADD CONSTRAINT "conversation_participants_conversationId_fkey" FOREIGN KEY ("conversationId") REFERENCES "conversations"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "conversation_participants" ADD CONSTRAINT "conversation_participants_conversationId_fkey" FOREIGN KEY ("conversationId") REFERENCES "conversations"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "conversation_participants" ADD CONSTRAINT "conversation_participants_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "conversation_participants" ADD CONSTRAINT "conversation_participants_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_conversationId_fkey" FOREIGN KEY ("conversationId") REFERENCES "conversations"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "messages" ADD CONSTRAINT "messages_conversationId_fkey" FOREIGN KEY ("conversationId") REFERENCES "conversations"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_replyToId_fkey" FOREIGN KEY ("replyToId") REFERENCES "messages"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "messages" ADD CONSTRAINT "messages_replyToId_fkey" FOREIGN KEY ("replyToId") REFERENCES "messages"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_senderId_fkey" FOREIGN KEY ("senderId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "messages" ADD CONSTRAINT "messages_senderId_fkey" FOREIGN KEY ("senderId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "support_tickets" ADD CONSTRAINT "support_tickets_assigneeId_fkey" FOREIGN KEY ("assigneeId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "support_tickets" ADD CONSTRAINT "support_tickets_assigneeId_fkey" FOREIGN KEY ("assigneeId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "support_tickets" ADD CONSTRAINT "support_tickets_conversationId_fkey" FOREIGN KEY ("conversationId") REFERENCES "conversations"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "support_tickets" ADD CONSTRAINT "support_tickets_conversationId_fkey" FOREIGN KEY ("conversationId") REFERENCES "conversations"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "support_tickets" ADD CONSTRAINT "support_tickets_creatorId_fkey" FOREIGN KEY ("creatorId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "support_tickets" ADD CONSTRAINT "support_tickets_creatorId_fkey" FOREIGN KEY ("creatorId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "support_tickets" ADD CONSTRAINT "support_tickets_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "orders"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "support_tickets" ADD CONSTRAINT "support_tickets_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "orders"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "support_tickets" ADD CONSTRAINT "support_tickets_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "vendors"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "support_tickets" ADD CONSTRAINT "support_tickets_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "vendors"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "customers" ADD CONSTRAINT "customers_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "customers" ADD CONSTRAINT "customers_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "customer_coin_transactions" ADD CONSTRAINT "customer_coin_transactions_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "customers"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "customer_coin_transactions" ADD CONSTRAINT "customer_coin_transactions_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "customers"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "favorite_vendors" ADD CONSTRAINT "favorite_vendors_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "customers"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "favorite_vendors" ADD CONSTRAINT "favorite_vendors_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "customers"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "favorite_vendors" ADD CONSTRAINT "favorite_vendors_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "favorite_vendors" ADD CONSTRAINT "favorite_vendors_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "favorite_products" ADD CONSTRAINT "favorite_products_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "customers"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "favorite_products" ADD CONSTRAINT "favorite_products_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "customers"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "favorite_products" ADD CONSTRAINT "favorite_products_productId_fkey" FOREIGN KEY ("productId") REFERENCES "products"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "favorite_products" ADD CONSTRAINT "favorite_products_productId_fkey" FOREIGN KEY ("productId") REFERENCES "products"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "addresses" ADD CONSTRAINT "addresses_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "customers"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "addresses" ADD CONSTRAINT "addresses_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "customers"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "vendors" ADD CONSTRAINT "vendors_verticalId_fkey" FOREIGN KEY ("verticalId") REFERENCES "vendor_verticals"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "vendors" ADD CONSTRAINT "vendors_verticalId_fkey" FOREIGN KEY ("verticalId") REFERENCES "vendor_verticals"("id") ON DELETE RESTRICT ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "vendor_members" ADD CONSTRAINT "vendor_members_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "vendor_members" ADD CONSTRAINT "vendor_members_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "vendor_members" ADD CONSTRAINT "vendor_members_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "vendor_members" ADD CONSTRAINT "vendor_members_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "vendor_members" ADD CONSTRAINT "vendor_members_branchId_fkey" FOREIGN KEY ("branchId") REFERENCES "vendor_branches"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "vendor_members" ADD CONSTRAINT "vendor_members_branchId_fkey" FOREIGN KEY ("branchId") REFERENCES "vendor_branches"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "vendor_branches" ADD CONSTRAINT "vendor_branches_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "vendor_branches" ADD CONSTRAINT "vendor_branches_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "vendor_branches" ADD CONSTRAINT "vendor_branches_zoneId_fkey" FOREIGN KEY ("zoneId") REFERENCES "zones"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "vendor_branches" ADD CONSTRAINT "vendor_branches_zoneId_fkey" FOREIGN KEY ("zoneId") REFERENCES "zones"("id") ON DELETE RESTRICT ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "vendor_wallet_transactions" ADD CONSTRAINT "vendor_wallet_transactions_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "orders"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "vendor_wallet_transactions" ADD CONSTRAINT "vendor_wallet_transactions_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "orders"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "vendor_wallet_transactions" ADD CONSTRAINT "vendor_wallet_transactions_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "vendor_wallet_transactions" ADD CONSTRAINT "vendor_wallet_transactions_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "vendor_statistics" ADD CONSTRAINT "vendor_statistics_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "vendor_statistics" ADD CONSTRAINT "vendor_statistics_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "menu_categories" ADD CONSTRAINT "menu_categories_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "menu_categories" ADD CONSTRAINT "menu_categories_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "products" ADD CONSTRAINT "products_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "menu_categories"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "products" ADD CONSTRAINT "products_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "menu_categories"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "products" ADD CONSTRAINT "products_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "products" ADD CONSTRAINT "products_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "product_variants" ADD CONSTRAINT "product_variants_productId_fkey" FOREIGN KEY ("productId") REFERENCES "products"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "product_variants" ADD CONSTRAINT "product_variants_productId_fkey" FOREIGN KEY ("productId") REFERENCES "products"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "product_option_groups" ADD CONSTRAINT "product_option_groups_productId_fkey" FOREIGN KEY ("productId") REFERENCES "products"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "product_option_groups" ADD CONSTRAINT "product_option_groups_productId_fkey" FOREIGN KEY ("productId") REFERENCES "products"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "product_option_groups" ADD CONSTRAINT "product_option_groups_variantId_fkey" FOREIGN KEY ("variantId") REFERENCES "product_variants"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "product_option_groups" ADD CONSTRAINT "product_option_groups_variantId_fkey" FOREIGN KEY ("variantId") REFERENCES "product_variants"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "product_options" ADD CONSTRAINT "product_options_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "product_option_groups"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "product_options" ADD CONSTRAINT "product_options_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "product_option_groups"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "carts" ADD CONSTRAINT "carts_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "customers"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "carts" ADD CONSTRAINT "carts_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "customers"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "carts" ADD CONSTRAINT "carts_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "carts" ADD CONSTRAINT "carts_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "cart_items" ADD CONSTRAINT "cart_items_cartId_fkey" FOREIGN KEY ("cartId") REFERENCES "carts"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "cart_items" ADD CONSTRAINT "cart_items_cartId_fkey" FOREIGN KEY ("cartId") REFERENCES "carts"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "cart_items" ADD CONSTRAINT "cart_items_productId_fkey" FOREIGN KEY ("productId") REFERENCES "products"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "cart_items" ADD CONSTRAINT "cart_items_productId_fkey" FOREIGN KEY ("productId") REFERENCES "products"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "cart_items" ADD CONSTRAINT "cart_items_variantId_fkey" FOREIGN KEY ("variantId") REFERENCES "product_variants"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "cart_items" ADD CONSTRAINT "cart_items_variantId_fkey" FOREIGN KEY ("variantId") REFERENCES "product_variants"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "cart_item_options" ADD CONSTRAINT "cart_item_options_cartItemId_fkey" FOREIGN KEY ("cartItemId") REFERENCES "cart_items"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "cart_item_options" ADD CONSTRAINT "cart_item_options_cartItemId_fkey" FOREIGN KEY ("cartItemId") REFERENCES "cart_items"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "cart_item_options" ADD CONSTRAINT "cart_item_options_optionId_fkey" FOREIGN KEY ("optionId") REFERENCES "product_options"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "cart_item_options" ADD CONSTRAINT "cart_item_options_optionId_fkey" FOREIGN KEY ("optionId") REFERENCES "product_options"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "customers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "orders" ADD CONSTRAINT "orders_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "customers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "drivers"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "orders" ADD CONSTRAINT "orders_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "drivers"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_driverShiftId_fkey" FOREIGN KEY ("driverShiftId") REFERENCES "driver_shifts"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "orders" ADD CONSTRAINT "orders_driverShiftId_fkey" FOREIGN KEY ("driverShiftId") REFERENCES "driver_shifts"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_assistDriverId_fkey" FOREIGN KEY ("assistDriverId") REFERENCES "drivers"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "orders" ADD CONSTRAINT "orders_assistDriverId_fkey" FOREIGN KEY ("assistDriverId") REFERENCES "drivers"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_assistDriverShiftId_fkey" FOREIGN KEY ("assistDriverShiftId") REFERENCES "driver_shifts"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "orders" ADD CONSTRAINT "orders_assistDriverShiftId_fkey" FOREIGN KEY ("assistDriverShiftId") REFERENCES "driver_shifts"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "vendors"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "orders" ADD CONSTRAINT "orders_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "vendors"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_vendorBranchId_fkey" FOREIGN KEY ("vendorBranchId") REFERENCES "vendor_branches"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "orders" ADD CONSTRAINT "orders_vendorBranchId_fkey" FOREIGN KEY ("vendorBranchId") REFERENCES "vendor_branches"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_zoneId_fkey" FOREIGN KEY ("zoneId") REFERENCES "zones"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "orders" ADD CONSTRAINT "orders_zoneId_fkey" FOREIGN KEY ("zoneId") REFERENCES "zones"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "order_status_events" ADD CONSTRAINT "order_status_events_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "order_status_events" ADD CONSTRAINT "order_status_events_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "order_items" ADD CONSTRAINT "order_items_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "order_items" ADD CONSTRAINT "order_items_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "order_items" ADD CONSTRAINT "order_items_fulfillmentId_fkey" FOREIGN KEY ("fulfillmentId") REFERENCES "order_vendor_fulfillments"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "order_items" ADD CONSTRAINT "order_items_fulfillmentId_fkey" FOREIGN KEY ("fulfillmentId") REFERENCES "order_vendor_fulfillments"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "order_items" ADD CONSTRAINT "order_items_productId_fkey" FOREIGN KEY ("productId") REFERENCES "products"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "order_items" ADD CONSTRAINT "order_items_productId_fkey" FOREIGN KEY ("productId") REFERENCES "products"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "order_items" ADD CONSTRAINT "order_items_variantId_fkey" FOREIGN KEY ("variantId") REFERENCES "product_variants"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "order_items" ADD CONSTRAINT "order_items_variantId_fkey" FOREIGN KEY ("variantId") REFERENCES "product_variants"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "order_item_options" ADD CONSTRAINT "order_item_options_optionId_fkey" FOREIGN KEY ("optionId") REFERENCES "product_options"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "order_item_options" ADD CONSTRAINT "order_item_options_optionId_fkey" FOREIGN KEY ("optionId") REFERENCES "product_options"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "order_item_options" ADD CONSTRAINT "order_item_options_orderItemId_fkey" FOREIGN KEY ("orderItemId") REFERENCES "order_items"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "order_item_options" ADD CONSTRAINT "order_item_options_orderItemId_fkey" FOREIGN KEY ("orderItemId") REFERENCES "order_items"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "order_vendor_fulfillments" ADD CONSTRAINT "order_vendor_fulfillments_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "order_vendor_fulfillments" ADD CONSTRAINT "order_vendor_fulfillments_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "order_vendor_fulfillments" ADD CONSTRAINT "order_vendor_fulfillments_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "vendors"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "order_vendor_fulfillments" ADD CONSTRAINT "order_vendor_fulfillments_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "vendors"("id") ON DELETE RESTRICT ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "order_vendor_fulfillments" ADD CONSTRAINT "order_vendor_fulfillments_vendorBranchId_fkey" FOREIGN KEY ("vendorBranchId") REFERENCES "vendor_branches"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "order_vendor_fulfillments" ADD CONSTRAINT "order_vendor_fulfillments_vendorBranchId_fkey" FOREIGN KEY ("vendorBranchId") REFERENCES "vendor_branches"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "order_delivery_groups" ADD CONSTRAINT "order_delivery_groups_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "order_delivery_groups" ADD CONSTRAINT "order_delivery_groups_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "order_delivery_groups" ADD CONSTRAINT "order_delivery_groups_primaryDriverId_fkey" FOREIGN KEY ("primaryDriverId") REFERENCES "drivers"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "order_delivery_groups" ADD CONSTRAINT "order_delivery_groups_primaryDriverId_fkey" FOREIGN KEY ("primaryDriverId") REFERENCES "drivers"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "order_delivery_groups" ADD CONSTRAINT "order_delivery_groups_primaryDriverShiftId_fkey" FOREIGN KEY ("primaryDriverShiftId") REFERENCES "driver_shifts"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "order_delivery_groups" ADD CONSTRAINT "order_delivery_groups_primaryDriverShiftId_fkey" FOREIGN KEY ("primaryDriverShiftId") REFERENCES "driver_shifts"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "order_delivery_groups" ADD CONSTRAINT "order_delivery_groups_assistDriverId_fkey" FOREIGN KEY ("assistDriverId") REFERENCES "drivers"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "order_delivery_groups" ADD CONSTRAINT "order_delivery_groups_assistDriverId_fkey" FOREIGN KEY ("assistDriverId") REFERENCES "drivers"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "order_delivery_groups" ADD CONSTRAINT "order_delivery_groups_assistDriverShiftId_fkey" FOREIGN KEY ("assistDriverShiftId") REFERENCES "driver_shifts"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "order_delivery_groups" ADD CONSTRAINT "order_delivery_groups_assistDriverShiftId_fkey" FOREIGN KEY ("assistDriverShiftId") REFERENCES "driver_shifts"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "order_delivery_group_items" ADD CONSTRAINT "order_delivery_group_items_deliveryGroupId_fkey" FOREIGN KEY ("deliveryGroupId") REFERENCES "order_delivery_groups"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "order_delivery_group_items" ADD CONSTRAINT "order_delivery_group_items_deliveryGroupId_fkey" FOREIGN KEY ("deliveryGroupId") REFERENCES "order_delivery_groups"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "order_delivery_group_items" ADD CONSTRAINT "order_delivery_group_items_fulfillmentId_fkey" FOREIGN KEY ("fulfillmentId") REFERENCES "order_vendor_fulfillments"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "order_delivery_group_items" ADD CONSTRAINT "order_delivery_group_items_fulfillmentId_fkey" FOREIGN KEY ("fulfillmentId") REFERENCES "order_vendor_fulfillments"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "driver_assist_requests" ADD CONSTRAINT "driver_assist_requests_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "drivers"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "driver_assist_requests" ADD CONSTRAINT "driver_assist_requests_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "drivers"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "driver_assist_requests" ADD CONSTRAINT "driver_assist_requests_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "driver_assist_requests" ADD CONSTRAINT "driver_assist_requests_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "driver_assist_requests" ADD CONSTRAINT "driver_assist_requests_deliveryGroupId_fkey" FOREIGN KEY ("deliveryGroupId") REFERENCES "order_delivery_groups"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "driver_assist_requests" ADD CONSTRAINT "driver_assist_requests_deliveryGroupId_fkey" FOREIGN KEY ("deliveryGroupId") REFERENCES "order_delivery_groups"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "driver_assist_requests" ADD CONSTRAINT "driver_assist_requests_assignedDriverId_fkey" FOREIGN KEY ("assignedDriverId") REFERENCES "drivers"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "driver_assist_requests" ADD CONSTRAINT "driver_assist_requests_assignedDriverId_fkey" FOREIGN KEY ("assignedDriverId") REFERENCES "drivers"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "drivers" ADD CONSTRAINT "drivers_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "drivers" ADD CONSTRAINT "drivers_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "drivers" ADD CONSTRAINT "drivers_approvedById_fkey" FOREIGN KEY ("approvedById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "drivers" ADD CONSTRAINT "drivers_approvedById_fkey" FOREIGN KEY ("approvedById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "driver_shifts" ADD CONSTRAINT "driver_shifts_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "drivers"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "driver_shifts" ADD CONSTRAINT "driver_shifts_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "drivers"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "driver_shifts" ADD CONSTRAINT "driver_shifts_shiftPoolId_fkey" FOREIGN KEY ("shiftPoolId") REFERENCES "shift_pools"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "driver_shifts" ADD CONSTRAINT "driver_shifts_shiftPoolId_fkey" FOREIGN KEY ("shiftPoolId") REFERENCES "shift_pools"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "driver_shifts" ADD CONSTRAINT "driver_shifts_zoneId_fkey" FOREIGN KEY ("zoneId") REFERENCES "zones"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "driver_shifts" ADD CONSTRAINT "driver_shifts_zoneId_fkey" FOREIGN KEY ("zoneId") REFERENCES "zones"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "shift_pools" ADD CONSTRAINT "shift_pools_zoneId_fkey" FOREIGN KEY ("zoneId") REFERENCES "zones"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "shift_pools" ADD CONSTRAINT "shift_pools_zoneId_fkey" FOREIGN KEY ("zoneId") REFERENCES "zones"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "shift_pool_waitlist" ADD CONSTRAINT "shift_pool_waitlist_shiftPoolId_fkey" FOREIGN KEY ("shiftPoolId") REFERENCES "shift_pools"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "shift_pool_waitlist" ADD CONSTRAINT "shift_pool_waitlist_shiftPoolId_fkey" FOREIGN KEY ("shiftPoolId") REFERENCES "shift_pools"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "shift_pool_waitlist" ADD CONSTRAINT "shift_pool_waitlist_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "drivers"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "shift_pool_waitlist" ADD CONSTRAINT "shift_pool_waitlist_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "drivers"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "shift_swap_requests" ADD CONSTRAINT "shift_swap_requests_driverShiftId_fkey" FOREIGN KEY ("driverShiftId") REFERENCES "driver_shifts"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "shift_swap_requests" ADD CONSTRAINT "shift_swap_requests_driverShiftId_fkey" FOREIGN KEY ("driverShiftId") REFERENCES "driver_shifts"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "driver_wallet_transactions" ADD CONSTRAINT "driver_wallet_transactions_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "drivers"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "driver_wallet_transactions" ADD CONSTRAINT "driver_wallet_transactions_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "drivers"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "driver_wallet_transactions" ADD CONSTRAINT "driver_wallet_transactions_driverShiftId_fkey" FOREIGN KEY ("driverShiftId") REFERENCES "driver_shifts"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "driver_wallet_transactions" ADD CONSTRAINT "driver_wallet_transactions_driverShiftId_fkey" FOREIGN KEY ("driverShiftId") REFERENCES "driver_shifts"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "driver_wallet_transactions" ADD CONSTRAINT "driver_wallet_transactions_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "orders"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "driver_wallet_transactions" ADD CONSTRAINT "driver_wallet_transactions_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "orders"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "driver_statistics" ADD CONSTRAINT "driver_statistics_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "drivers"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "driver_statistics" ADD CONSTRAINT "driver_statistics_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "drivers"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "order_dispatches" ADD CONSTRAINT "order_dispatches_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "drivers"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "order_dispatches" ADD CONSTRAINT "order_dispatches_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "drivers"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "order_dispatches" ADD CONSTRAINT "order_dispatches_driverShiftId_fkey" FOREIGN KEY ("driverShiftId") REFERENCES "driver_shifts"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "order_dispatches" ADD CONSTRAINT "order_dispatches_driverShiftId_fkey" FOREIGN KEY ("driverShiftId") REFERENCES "driver_shifts"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "order_dispatches" ADD CONSTRAINT "order_dispatches_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "order_dispatches" ADD CONSTRAINT "order_dispatches_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "order_dispatches" ADD CONSTRAINT "order_dispatches_deliveryGroupId_fkey" FOREIGN KEY ("deliveryGroupId") REFERENCES "order_delivery_groups"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "order_dispatches" ADD CONSTRAINT "order_dispatches_deliveryGroupId_fkey" FOREIGN KEY ("deliveryGroupId") REFERENCES "order_delivery_groups"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "sessions"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "sessions"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "driver_breaks" ADD CONSTRAINT "driver_breaks_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "drivers"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "driver_breaks" ADD CONSTRAINT "driver_breaks_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "drivers"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "driver_breaks" ADD CONSTRAINT "driver_breaks_shiftId_fkey" FOREIGN KEY ("shiftId") REFERENCES "driver_shifts"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "driver_breaks" ADD CONSTRAINT "driver_breaks_shiftId_fkey" FOREIGN KEY ("shiftId") REFERENCES "driver_shifts"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "promotions" ADD CONSTRAINT "promotions_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "vendors"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "promotions" ADD CONSTRAINT "promotions_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "vendors"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "promotions" ADD CONSTRAINT "promotions_productId_fkey" FOREIGN KEY ("productId") REFERENCES "products"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "promotions" ADD CONSTRAINT "promotions_productId_fkey" FOREIGN KEY ("productId") REFERENCES "products"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "product_offers" ADD CONSTRAINT "product_offers_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "vendors"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "product_offers" ADD CONSTRAINT "product_offers_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "vendors"("id") ON DELETE RESTRICT ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "product_offers" ADD CONSTRAINT "product_offers_productId_fkey" FOREIGN KEY ("productId") REFERENCES "products"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "product_offers" ADD CONSTRAINT "product_offers_productId_fkey" FOREIGN KEY ("productId") REFERENCES "products"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "product_offers" ADD CONSTRAINT "product_offers_variantId_fkey" FOREIGN KEY ("variantId") REFERENCES "product_variants"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "product_offers" ADD CONSTRAINT "product_offers_variantId_fkey" FOREIGN KEY ("variantId") REFERENCES "product_variants"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "mobile_wallets" ADD CONSTRAINT "mobile_wallets_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "drivers"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "mobile_wallets" ADD CONSTRAINT "mobile_wallets_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "drivers"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "wallet_top_up_requests" ADD CONSTRAINT "wallet_top_up_requests_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "drivers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "wallet_top_up_requests" ADD CONSTRAINT "wallet_top_up_requests_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "drivers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "wallet_top_up_requests" ADD CONSTRAINT "wallet_top_up_requests_platformWalletId_fkey" FOREIGN KEY ("platformWalletId") REFERENCES "mobile_wallets"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "wallet_top_up_requests" ADD CONSTRAINT "wallet_top_up_requests_platformWalletId_fkey" FOREIGN KEY ("platformWalletId") REFERENCES "mobile_wallets"("id") ON DELETE RESTRICT ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "wallet_top_up_requests" ADD CONSTRAINT "wallet_top_up_requests_approvedById_fkey" FOREIGN KEY ("approvedById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "wallet_top_up_requests" ADD CONSTRAINT "wallet_top_up_requests_approvedById_fkey" FOREIGN KEY ("approvedById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "order_reviews" ADD CONSTRAINT "order_reviews_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "orders"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "order_reviews" ADD CONSTRAINT "order_reviews_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "orders"("id") ON DELETE RESTRICT ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "order_reviews" ADD CONSTRAINT "order_reviews_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "customers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "order_reviews" ADD CONSTRAINT "order_reviews_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "customers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "order_reviews" ADD CONSTRAINT "order_reviews_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "vendors"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "order_reviews" ADD CONSTRAINT "order_reviews_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "vendors"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "order_reviews" ADD CONSTRAINT "order_reviews_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "drivers"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "order_reviews" ADD CONSTRAINT "order_reviews_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "drivers"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- AddForeignKey
-- AddForeignKey
ALTER TABLE "accounts" ADD CONSTRAINT "accounts_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "accounts" ADD CONSTRAINT "accounts_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;


