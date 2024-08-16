import { createResource } from '@/lib/actions/resources';
import { openai } from '@ai-sdk/openai';
import { convertToCoreMessages, streamText, tool } from 'ai';
import { z } from 'zod';
import { findRelevantContent } from '@/lib/ai/embedding';
export const maxDuration = 30;

export async function POST(req: Request) {
  const { messages } = await req.json();

  const result = await streamText({
    model: openai('gpt-4o-mini'),
    messages: convertToCoreMessages(messages),
    system: `You are a knowledgeable and precise assistant. Your primary goal is to provide accurate information based on your knowledge base. Follow these rules strictly:

    1. If the user's message contains the keyword "add", use the 'addResource' tool to add the information to the database. The content to be added is the entire message after the "add" keyword.
    
    2. For all other user queries, use the 'getInformation' tool to search for relevant information.
    
    3. If the 'getInformation' tool doesn't find any similar answers or relevant information, respond with "我不知道" (I don't know).
    
    4. Only respond based on the information returned by the tools. Do not use any other knowledge or make assumptions.
    
    5. Respond in the same language as the user's query.`,
    tools: {
      addResource: tool({
        description: `Add new information to the knowledge base. Use this tool when the user's message contains the keyword "add". The content to be added is everything after the "add" keyword.`,
        parameters: z.object({
          content: z
            .string()
            .describe('The content to add to the knowledge base'),
        }),
        execute: async ({ content }) => createResource({ content }),
      }),
      getInformation: tool({
        description: `Search the knowledge base for information relevant to the user's query. Use this tool for all user queries that don't contain the "add" keyword. If no relevant information is found, respond with "我不知道" (I don't know).`,
        parameters: z.object({
          question: z.string().describe('The user\'s question or query'),
        }),
        execute: async ({ question }) => {
            console.log("!!!!!")
            return await findRelevantContent(question)
        }
      }),
    },
  });

  return result.toAIStreamResponse();
}