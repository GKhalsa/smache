# Frontend code example

```js
import { Socket } from 'phoenix';

const socket = new Socket('ws://localhost:4000/socket', {});

socket.connect();

const ROOM_NAME = 'myRoom1234';
const MAIN_SUB = `${ROOM_NAME}_sub`;
const MAIN_PUB = `${ROOM_NAME}_pub`

const chan = socket.channel(ROOM_NAME);
chan.join();

/**
  * YOU MUST USE THE FOLLOWING SYNTAX FOR ROOM NAMES!
  *
  * cannot use snake_case for event names but
  * must snake_case event types
  * to help identify if the event is pub or sub
  *
  * Example: myroomname_sub
  * Example: myroomname_pub
  * Example: asdf1234_sub
  * Example: asdf1234_pub
  * Example: myRoomName_sub
  * Example: myRoomName_pub
  */

// subscribe to all published events
chan.on(ROOM_SUB, ({ key, data } }) => {
  console.log(key, data);
});

// ask for data without changing server state
// do this when first joining
chan.push(ROOM_SUB, {
  body: {
    key: '1',
  },
});

// publish updated state changes to all subscribers
chan.push(ROOM_PUB, {
  body: {
    key: '1',
    data: {
      sha: new Date().getTime(),
    },
  },
});
```
