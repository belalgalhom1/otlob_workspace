import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { RegisterDeviceDto } from './dto/device.dto';

@Injectable()
export class DevicesService {
  private readonly logger = new Logger(DevicesService.name);

  constructor(private prisma: PrismaService) {}

  async register(userId: string, dto: RegisterDeviceDto) {
    const device = await this.prisma.device.upsert({
      where: { token: dto.token },
      update: {
        userId,
        platform: dto.platform,
        lastActive: new Date(),
      },
      create: {
        token: dto.token,
        platform: dto.platform,
        userId,
      },
    });
    this.logger.log(
      `Registered ${dto.platform} FCM token (...${dto.token.slice(-10)}) for user ${userId}`,
    );
    return device;
  }

  async remove(userId: string, token: string) {
    const result = await this.prisma.device.deleteMany({
      where: {
        userId,
        token,
      },
    });
    this.logger.log(
      `Removed ${result.count} FCM device record(s) (...${token.slice(-10)}) for user ${userId}`,
    );
    return result;
  }
}
