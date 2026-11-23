import { Job } from 'bullmq';
import {
  DEFAULT_ANDROID_NOTIFICATION_CHANNEL_ID,
  PushProcessor,
} from './push.processor';
import { PUSH_JOBS } from '../queue/queues.constants';
import { PushJob } from './push.interface';

describe('PushProcessor', () => {
  const messagingMock = {
    send: jest.fn(),
    sendEachForMulticast: jest.fn(),
    subscribeToTopic: jest.fn(),
    unsubscribeFromTopic: jest.fn(),
  };

  const prismaMock = {
    device: {
      deleteMany: jest.fn(),
    },
  };

  let processor: PushProcessor;

  beforeEach(() => {
    jest.clearAllMocks();
    processor = new PushProcessor(messagingMock as any, prismaMock as any);
  });

  it('sends default sound and versioned high-importance Android channel for device notifications', async () => {
    messagingMock.sendEachForMulticast.mockResolvedValue({
      successCount: 1,
      failureCount: 0,
      responses: [{ success: true }],
    });

    const job = {
      name: PUSH_JOBS.SEND_TO_DEVICES,
      data: {
        action: 'SEND',
        tokens: ['token-1'],
        title: 'New Order',
        body: 'Order #101 placed',
        data: { orderId: 'ord-1' },
      },
    } as unknown as Job<PushJob>;

    await processor.process(job);

    expect(messagingMock.sendEachForMulticast).toHaveBeenCalledWith(
      expect.objectContaining({
        tokens: ['token-1'],
        notification: { title: 'New Order', body: 'Order #101 placed' },
        android: expect.objectContaining({
          priority: 'high',
          notification: expect.objectContaining({
            channelId: DEFAULT_ANDROID_NOTIFICATION_CHANNEL_ID,
            sound: 'default',
            defaultSound: true,
            defaultVibrateTimings: true,
            priority: 'max',
            visibility: 'public',
          }),
        }),
        apns: expect.objectContaining({
          payload: expect.objectContaining({
            aps: expect.objectContaining({
              contentAvailable: true,
              sound: 'default',
            }),
          }),
        }),
      }),
    );
  });

  it('sends default sound and versioned high-importance Android channel for topic announcements', async () => {
    messagingMock.send.mockResolvedValue('msg-123');

    const job = {
      name: PUSH_JOBS.SEND_TO_TOPIC,
      data: {
        action: 'SEND',
        topic: 'topic_all',
        title: 'Announcement',
        body: 'Hello everyone',
      },
    } as unknown as Job<PushJob>;

    await processor.process(job);

    expect(messagingMock.send).toHaveBeenCalledWith(
      expect.objectContaining({
        topic: 'topic_all',
        android: expect.objectContaining({
          priority: 'high',
          notification: expect.objectContaining({
            channelId: DEFAULT_ANDROID_NOTIFICATION_CHANNEL_ID,
            sound: 'default',
            defaultSound: true,
          }),
        }),
        apns: expect.objectContaining({
          payload: expect.objectContaining({
            aps: expect.objectContaining({
              sound: 'default',
            }),
          }),
        }),
      }),
    );
  });
});
