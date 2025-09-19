import aiohttp, os
async def query_ai(prompt, ai_token, model="deepseek-ai/DeepSeek-R1:fireworks-ai"):
    url = "https://router.huggingface.co/v1/chat/completions"
    payload = {
        "messages": [{"role": "user", "content": prompt}],
        "top_p": 1,
        "model": model
    }
    headers = {"Authorization": f"Bearer {ai_token}", "Content-Type": "application/json"}
    async with aiohttp.ClientSession() as session:
        async with session.post(url, json=payload, headers=headers) as resp:
            res = await resp.json()
            return res["choices"][0]["message"]["content"] if "choices" in res else res.get("error", "")