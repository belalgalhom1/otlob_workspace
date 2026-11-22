import { Injectable, NotFoundException } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { Prisma, Role } from '@prisma/client';
import { DriverErrors } from '../../../common/constants/response.constants';
import { AuditLogCreatedEvent } from '../../../common/events';
import { EVENTS } from '../../../common/events/event-names';
import type { JwtAccessPayload } from '../../../common/interfaces/jwt-payload.interface';
import { DriverManagersService } from '../driver-managers.service';
import { DriverRankingRepository } from './driver-ranking.repository';
import {
  QueryDeliveryIncidentsDto,
  UpdateDeliveryIncidentDto,
} from './dto/driver-ranking.dto';

@Injectable()
export class DriverDeliveryIncidentsService {
  constructor(
    private readonly rankingRepository: DriverRankingRepository,
    private readonly driverManagersService: DriverManagersService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async listIncidents(dto: QueryDeliveryIncidentsDto, actor: JwtAccessPayload) {
    const page = dto.page ?? 1;
    const limit = dto.limit ?? 20;
    const skip = (page - 1) * limit;

    let scopedDriverIds: string[] | null = null;
    if (actor.role === Role.DRIVER_MANAGER) {
      if (dto.driverId) {
        await this.driverManagersService.assertManagesDriver(
          actor.sub,
          dto.driverId,
        );
      } else {
        scopedDriverIds = await this.driverManagersService.getManagedDriverIds(
          actor.sub,
        );
        if (scopedDriverIds.length === 0) {
          return {
            data: [],
            meta: { total: 0, page, limit, totalPages: 0 },
          };
        }
      }
    }

    const where: Prisma.DriverDeliveryIncidentWhereInput = {
      ...(dto.responsibility ? { responsibility: dto.responsibility } : {}),
      ...(dto.driverId
        ? { driverId: dto.driverId }
        : scopedDriverIds
          ? { driverId: { in: scopedDriverIds } }
          : {}),
    };

    const [rows, total] = await this.rankingRepository.listIncidents(
      where,
      skip,
      limit,
    );

    return {
      data: rows.map(({ driver, order, ...rest }) => ({
        ...rest,
        driverName: driver.name,
        orderNumber: order.orderNumber,
      })),
      meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
  }

  async reviewIncident(
    incidentId: string,
    dto: UpdateDeliveryIncidentDto,
    actor: JwtAccessPayload,
  ) {
    const existing = await this.rankingRepository.findIncidentById(incidentId);
    if (!existing) {
      throw new NotFoundException(DriverErrors.DELIVERY_INCIDENT_NOT_FOUND);
    }

    const updated = await this.rankingRepository.updateIncidentReview(
      incidentId,
      {
        responsibility: dto.responsibility,
        reviewNote: dto.reviewNote?.trim() || null,
        reviewedByUserId: actor.sub,
        reviewedAt: new Date(),
      },
    );

    this.eventEmitter.emit(
      EVENTS.AUDIT_LOG_CREATED,
      new AuditLogCreatedEvent(
        actor.sub,
        null,
        null,
        'UPDATE',
        'REVIEW_DELIVERY_INCIDENT',
        'DriverDeliveryIncident',
        incidentId,
        {
          responsibility: updated.responsibility,
          reviewNote: updated.reviewNote,
        },
        {
          responsibility: existing.responsibility,
          reviewNote: existing.reviewNote,
        },
      ),
    );

    const { driver, order, ...rest } = updated;
    return {
      ...rest,
      driverName: driver.name,
      orderNumber: order.orderNumber,
    };
  }
}
