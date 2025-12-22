from tools.bedrock_insights.insights import InsightPromptBuilder, generate_insights


def test_prompt_builder_includes_context_and_focus():
    context = "Example service graph"
    prompt = InsightPromptBuilder().render(context)

    assert "Example service graph" in prompt
    assert "Missing telemetry" in prompt
    assert "Focus:" in prompt


def test_generate_insights_offline_returns_placeholders():
    results = generate_insights("ctx", offline=True)

    assert "prompt" in results
    assert results["claude"].startswith("[Claude OFFLINE SAMPLE]")
    assert results["titan"].startswith("[Titan OFFLINE SAMPLE]")
