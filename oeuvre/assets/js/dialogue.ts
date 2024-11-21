import { assign, createActor, setup, fromPromise } from "xstate";

import { speechstate, SpeechStateExternalEvent } from "speechstate";
const azureCredentials = {
  endpoint:
    "https://swedencentral.api.cognitive.microsoft.com/sts/v1.0/issueToken",
  key: "d20e2774178d48d7941be63ee9971853",
};

const settings = {
  azureCredentials: azureCredentials,
  azureRegion: "swedencentral",
  asrDefaultCompleteTimeout: 0,
  asrDefaultNoInputTimeout: 10000,
  locale: "en-US",
  ttsDefaultVoice: "en-US-EmmaMultilingualNeural",
};

interface Move {
  role: "assistant" | "user";
  content: string;
}

const dmMachine = setup({
  actors: {
    callGpt: fromPromise<any, { description: string; history: Move[] }>(
      async ({ input }) => {
        const response = await fetch("http://localhost:4000/ollama/chat", {
          headers: {
            "Content-Type": "application/json",
          },
          method: "POST",
          body: JSON.stringify(input),
        });
        return response.json();
      },
    ),
  },
  actions: {
    /** speak and listen */
    speak_greeting: ({ context }) => {
      context.ssRef.send({
        type: "SPEAK",
        value: {
          utterance: context.is.moves[0].content,
        },
      });
    },
    speak_stream: ({ context }) => {
      context.ssRef.send({
        type: "SPEAK",
        value: {
          utterance: "",
          stream: "http://localhost:4000/sse",
        },
      });
    },
    listen: ({ context }) =>
      context.ssRef.send({
        type: "LISTEN",
      }),

    /** update rules */
    enqueue_recognition_result: assign(({ context, event }) => {
      const utterance = (event as any).value[0].utterance;
      const newIS = {
        ...context.is,
        moves: [
          ...context.is.moves,
          {
            role: "user",
            content: utterance,
          },
        ] as any,
      };
      console.log("[IS enqueue_recognition_result]", newIS);
      return { is: newIS };
    }),
    enqueue_input_timeout: assign(({ context }) => {
      const utterance =
        "(the user is not saying anything or you can't hear them)";
      const newIS = {
        ...context.is,
        moves: [
          ...context.is.moves,
          {
            role: "user",
            content: utterance,
          },
        ] as any, // FIXME
      };
      console.log("[IS enqueue_input_timeout]", newIS);
      return { is: newIS };
    }),
    enqueue_assistant_move: assign(({ context, event }) => {
      const newIS = {
        ...context.is,
        moves: [...context.is.moves, (event as any).output],
      } as any;
      console.log("[IS enqueue_pending_from_llm]", newIS);
      return { is: newIS };
    }),
  },
  types: {} as {
    context: {
      ssRef?: any;
      is: {
        input: string[];
        moves: Move[];
      };
      imageDescription?: string;
    };
    events:
      | SpeechStateExternalEvent
      | { type: "SETUP"; value: string }
      | { type: "START" };
  },
}).createMachine({
  context: ({ spawn }) => ({
    ssRef: spawn(speechstate, { input: settings }),
    is: {
      input: [],
      moves: [
        {
          role: "assistant",
          content: "Hi there! Let's start our discussion!",
        },
      ],
      image: "",
    },
  }),
  id: "DM",
  initial: "Prepare",
  on: {
    SETUP: {
      target: ".Ready",
      actions: assign(({ event }) => ({ imageDescription: event.value })),
    },
    // TODO: implement ASRTTS_READY
  },
  states: {
    Prepare: {
      entry: ({ context }) => context.ssRef.send({ type: "PREPARE" }),
    },
    Ready: {
      entry: [({ context }) => console.log(context)],
      on: {
        START: "Main",
      },
    },
    Main: {
      entry: ["speak_greeting"],
      on: { SPEAK_COMPLETE: { target: "Ask" } },
    },
    Ask: {
      entry: "listen",
      on: {
        RECOGNISED: {
          target: "Respond",
          actions: { type: "enqueue_recognition_result" },
        },
        ASR_NOINPUT: {
          target: "Respond",
          actions: { type: "enqueue_input_timeout" },
        },
      },
    },
    Respond: {
      type: "parallel",
      states: {
        CallGpt: {
          invoke: {
            src: "callGpt",
            input: ({ context }) => ({
              description: context.imageDescription!,
              history: context.is.moves,
            }),
            onDone: { actions: "enqueue_assistant_move" },
          },
        },
        Speak: { entry: { type: "speak_stream" } },
      },
    },
  },
});

export const dmActor = createActor(dmMachine, {
  // inspect: inspector.inspect,
});
