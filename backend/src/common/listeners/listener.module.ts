import { Global, Module } from '@nestjs/common';

import { MailListener } from './mail.listener';
import { ChatListener } from './chat.listener';
import { NotificationListener } from './notification.listener';
import { SocketListener } from './socket.listener';
import { OrderListener } from './order.listener';
import { DriverListener } from './driver.listener';
import { DriverAssistListener } from './driver-assist.listener';
import { ShiftListener } from './shift.listener';
import { AuditLogListener } from './audit-log.listener';
import { DispatchListener } from './dispatch.listener';
import { CartListener } from './cart.listener';
import { ReviewListener } from './review.listener';
import { SettingsListener } from './settings.listener';
import { WalletListener } from './wallet.listener';
import { CartModule } from '../../features/cart/cart.module';
import { OrderSharedModule } from '../orders/order-shared.module';

const LISTENERS = [
  MailListener,
  ChatListener,
  NotificationListener,
  OrderListener,
  DriverListener,
  DriverAssistListener,
  ShiftListener,
  AuditLogListener,
  SocketListener,
  DispatchListener,
  CartListener,
  ReviewListener,
  SettingsListener,
  WalletListener,
];

@Global()
@Module({
  imports: [
    OrderSharedModule,
    CartModule, // provides CartService for EventsProcessor
  ],
  providers: LISTENERS,
  exports: LISTENERS,
})
export class ListenersModule {}
