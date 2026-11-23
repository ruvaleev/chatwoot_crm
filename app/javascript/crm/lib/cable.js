// Real-time events over Chatwoot's RoomChannel. Presence pings go over the same WebSocket, so the app makes no
// HTTP requests while idle (crm/PRD.md, AC D.8).
import { createConsumer } from '@rails/actioncable';

const PRESENCE_INTERVAL = 20000;

export const connectCable = ({
  pubsubToken,
  accountId,
  userId,
  onEvent,
  onReconnect,
}) => {
  const consumer = createConsumer();
  let wasDisconnected = false;
  const subscription = consumer.subscriptions.create(
    {
      channel: 'RoomChannel',
      pubsub_token: pubsubToken,
      account_id: accountId,
      user_id: userId,
    },
    {
      received: ({ event, data }) => {
        if (data?.account_id && Number(data.account_id) !== Number(accountId))
          return;
        onEvent(event, data);
      },
      connected: () => {
        if (wasDisconnected) onReconnect();
        wasDisconnected = false;
      },
      disconnected: () => {
        wasDisconnected = true;
      },
    }
  );
  const presence = setInterval(
    () => subscription.perform('update_presence'),
    PRESENCE_INTERVAL
  );
  return () => {
    clearInterval(presence);
    consumer.disconnect();
  };
};
