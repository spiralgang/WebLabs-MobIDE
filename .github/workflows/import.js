import OpenAI from "openai";

const openai = new OpenAI();

const prompt = `
I want to build a this apk, inspect the repository to provide a roadmap for future development immediate steps
and fix all .github/workflows errors in the repository then come back for next orders.
After you make a plan for the directory 
structure you'll personally need, then get your dependencies. Only supply 
your reasoning at the beginning and end, not throughout the whole time, no talk back unless it's high risk error pertaining.
`.trim();

const response = await openai.responses.create({
    model: "gpt-5",
    input: [
        {
            role: "user",
            content: prompt,
        },
    ],
});

console.log(response.output_text);
