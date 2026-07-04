import asyncio
from unittest.mock import AsyncMock, MagicMock, patch
import sys
import os

# Ensure the script directory is in the path
sys.path.insert(0, os.path.dirname(__file__))

# Mocking external dependencies
sys.modules['nimpy'] = MagicMock()
sys.modules['clang'] = MagicMock()
sys.modules['clang.cindex'] = MagicMock()
sys.modules['langchain'] = MagicMock()
sys.modules['langchain.llms'] = MagicMock()
sys.modules['langchain.chains'] = MagicMock()
sys.modules['langchain.memory'] = MagicMock()

# Now import the actual classes
from matrixxx import HostAgent, LivingEnvironment, HybridAgent

async def test_actual_update_loop_logic():
    # Setup
    host = HostAgent()
    env = host.env

    # We want to track calls to update_state but still have it update the state
    original_update_state = env.update_state
    mock_update_state = AsyncMock(side_effect=original_update_state)
    env.update_state = mock_update_state

    # Create real agents but mock their name and register them
    # HybridAgent.__init__ calls self.env.subscribe(self.on_env_update)
    agent1 = HybridAgent("Agent1", env, "Test Prompt 1")
    agent2 = HybridAgent("Agent2", env, "Test Prompt 2")

    # Register them manually in the host
    host.register_agent(agent1)
    host.register_agent(agent2)

    host.running = True

    real_sleep = asyncio.sleep

    async def mock_sleep(delay):
        if delay == 10:
            # First iteration of loop
            return
        await real_sleep(delay)

    with patch('asyncio.sleep', side_effect=mock_sleep):
        # We start the task and then stop it after one cycle
        task = asyncio.create_task(host.update_loop())

        # Give it a bit of time to run one cycle
        # We can poll the state until it's updated or just wait a tiny bit
        for _ in range(40): # max 2s
            await real_sleep(0.05)
            # 2 agents * (1 prompt + 1 code update) = 4 calls
            if mock_update_state.call_count >= 4:
                # Stop the loop after the first cycle
                host.running = False
                break

        try:
            await asyncio.wait_for(task, timeout=5.0)
        except (asyncio.TimeoutError, asyncio.CancelledError):
            pass

    # Verification of ACTUAL matrixxx.py logic
    # Total calls for 1 cycle with 2 agents: 2 prompt updates + 2 code updates
    assert mock_update_state.call_count >= 4

    # Check that at least cycle 0 was executed and stored in the env state correctly
    # Since multiple cycles might run, we check that keys exist and contain some valid data.
    assert 'prompt_update_Agent1' in env.state
    assert 'Agent update cycle' in env.state['prompt_update_Agent1']
    assert 'Agent1' in env.state['prompt_update_Agent1']

    assert 'code_update_Agent1' in env.state
    assert 'int dynamic_func()' in env.state['code_update_Agent1']

    assert 'prompt_update_Agent2' in env.state
    assert 'Agent2' in env.state['prompt_update_Agent2']

    print("Functional test on actual HostAgent passed!")

if __name__ == "__main__":
    asyncio.run(test_actual_update_loop_logic())
