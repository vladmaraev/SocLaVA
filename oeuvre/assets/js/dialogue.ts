import { assign, createActor, setup, fromPromise } from "xstate";

import { speechstate, SpeechStateExternalEvent } from "speechstate";

const settings = {
  azureCredentials: "azureToken",
  azureRegion: "swedencentral",
  asrDefaultCompleteTimeout: 0,
  asrDefaultNoInputTimeout: 10000,
  locale: "en-GB",
  ttsDefaultVoice: "en-GB-SoniaNeural",
};

interface Move {
  role: "assistant" | "user";
  content: string;
}

const dmMachine = setup({
  actors: {
    callGpt: fromPromise<any, { description: string; history: Move[] }>(
      async ({ input }) => {
        const response = await fetch("ollama/chat", {
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
          stream: "sse",
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
      console.log("[IS enqueue_assistant_move]", event.output);
      const newIS = {
        ...context.is,
        moves: [...context.is.moves, (event as any).output],
      } as any;
      console.log("[IS enqueue_assistant_move]", newIS);
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
          actions: { type: "enqueue_recognition_result" },
        },
        ASR_NOINPUT: {
          actions: { type: "enqueue_input_timeout" },
        },
        LISTEN_COMPLETE: {
          target: "Respond",
        },
      },
    },
    Respond: {
      type: "parallel",
      states: {
        CallGpt: {
          initial: "Calling",
          states: {
            Calling: {
              invoke: {
                src: "callGpt",
                input: ({ context }) => ({
                  description: context.imageDescription!,
                  history: context.is.moves,
                }),
                onDone: { actions: "enqueue_assistant_move", target: "Called" },
              },
            },
            Called: { type: "final" },
          },
        },
        Speak: {
          initial: "Speaking",
          states: {
            Speaking: {
              entry: { type: "speak_stream" },
              on: { SPEAK_COMPLETE: "Spoken" },
            },
            Spoken: { type: "final" },
          },
        },
      },
      onDone: "Ask",
    },
  },
});

export const dmActor = createActor(dmMachine, {
  // inspect: inspector.inspect,
});
