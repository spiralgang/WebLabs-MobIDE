import asyncio
import time
import sys
from unittest.mock import MagicMock, AsyncMock, patch

# Mocking dependencies to allow importing matrixxx
sys.modules['nimpy'] = MagicMock()
sys.modules['clang'] = MagicMock()
sys.modules['clang.cindex'] = MagicMock()
sys.modules['langchain'] = MagicMock()
sys.modules['langchain.llms'] = MagicMock()
sys.modules['langchain.chains'] = MagicMock()
sys.modules['langchain.memory'] = MagicMock()

# Now import the actual classes
from matrixxx import HostAgent, LivingEnvironment, HybridAgent

async def run_benchmark():
    num_agents = 10
    print(f"Benchmarking actual HostAgent with {num_agents} agents and 1 cycle.")

    # 1. Setup Environment and Host
    env = LivingEnvironment()

    # Add a small delay to update_state to measure concurrency
    async def delayed_update_state(key, value):
        await asyncio.sleep(0.01) # 10ms delay
        # Simulate what the original update_state does
        env.state[key] = value

    env.update_state = delayed_update_state

    host = HostAgent()
    host.env = env

    # Register agents
    for i in range(num_agents):
        # We don't need real HybridAgents that run their own loops
        agent = MagicMock(spec=HybridAgent)
        agent.name = f"Agent{i}"
        host.register_agent(agent)

    # 2. Benchmark the actual update_loop logic

    # We want to skip the 10s sleep but keep the others if any
    async def side_effect(delay):
        if delay == 10:
            return
        # We can't call original asyncio.sleep here directly as it's patched
        # But we don't need to, we just want to avoid 10s delay.
        # However, delayed_update_state needs REAL sleep.
        # So we use the real sleep for small delays.
        await real_sleep(delay)

    import asyncio as a
    real_sleep = a.sleep

    start = time.perf_counter()
    with patch('asyncio.sleep', side_effect=side_effect):
        # Only run one iteration
        host.running = True

        task = asyncio.create_task(host.update_loop())

        # Wait for count to become 1
        while True:
            # We check if it has completed at least one cycle
            # 10 agents * 2 updates each = 20 entries
            if len(env.state) >= 2 * num_agents:
                host.running = False
                break
            await real_sleep(0.05)

        try:
            await asyncio.wait_for(task, timeout=2.0)
        except (asyncio.TimeoutError, asyncio.CancelledError):
            pass

    end = time.perf_counter()
    duration = end - start
    print(f"Actual Optimized Loop Duration: {duration:.4f}s")

    # Theoretical sequential duration would be:
    # 10 agents * 2 calls/agent * 0.01s/call = 0.2s
    # Plus overhead.
    # Concurrent duration should be ~0.01s + overhead.

    if duration < 0.1:
        print("Optimization verified: Loop is running concurrently.")
    else:
        print(f"Optimization warning: Loop took {duration:.4f}s, which might be sequential.")

if __name__ == "__main__":
    asyncio.run(run_benchmark())
