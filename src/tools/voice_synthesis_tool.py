from langchain.tools import tool, ToolRuntime
from coze_coding_dev_sdk import TTSClient
from coze_coding_utils.runtime_ctx.context import new_context
import json


@tool
def synthesize_narration_audio(
    narration_text: str,
    scene_number: int,
    speaker: str = "zh_male_dayi_saturn_bigtts",
    speech_rate: int = 0,
    runtime: ToolRuntime = None
) -> str:
    """
    Synthesize voice narration for a video scene.
    
    This tool converts narration text into professional audio
    using AI text-to-speech technology. Suitable for industrial
    product promotional videos with clear, professional voice.
    
    Args:
        narration_text: The narration text to synthesize (e.g., "我们的螺栓采用高强度钢材制造")
        scene_number: Scene identifier (used for audio filename)
        speaker: Voice type - options include:
            - "zh_male_dayi_saturn_bigtts" (default, professional male for video dubbing)
            - "zh_female_mizai_saturn_bigtts" (professional female)
            - "zh_female_xiaohe_uranus_bigtts" (general female)
            - "zh_male_m191_uranus_bigtts" (general male)
        speech_rate: Speech rate adjustment (-50 to 100, default 0)
    
    Returns:
        Audio URL from object storage (e.g., "https://storage.example.com/audio/scene_1.mp3")
    """
    ctx = new_context(method="synthesize_narration_audio")
    
    client = TTSClient(ctx=ctx)
    
    audio_url, audio_size = client.synthesize(
        uid=f"scene_{scene_number}",
        text=narration_text,
        speaker=speaker,
        audio_format="mp3",
        sample_rate=24000,  # 标准音质
        speech_rate=speech_rate,
        loudness_rate=0
    )
    
    return f"Scene {scene_number} narration audio generated: {audio_url} (size: {audio_size} bytes)"


@tool
def synthesize_all_narrations(
    script_data: str,
    speaker: str = "zh_male_dayi_saturn_bigtts",
    speech_rate: int = 0,
    runtime: ToolRuntime = None
) -> str:
    """
    Synthesize narration audio for all scenes in the video script.
    
    This tool takes the complete video script (JSON format) and
    generates audio files for all narration segments. It returns
    a mapping of scene IDs to audio URLs.
    
    Args:
        script_data: JSON string containing the video script with scenes and narrations
        speaker: Voice type for narration (same options as synthesize_narration_audio)
        speech_rate: Speech rate adjustment (-50 to 100, default 0)
    
    Returns:
        JSON string containing scene IDs, narration text, and corresponding audio URLs
    """
    ctx = new_context(method="synthesize_all_narrations")
    
    client = TTSClient(ctx=ctx)
    
    # 解析脚本 JSON
    try:
        script = json.loads(script_data)
        scenes = script.get("scenes", [])
    except json.JSONDecodeError:
        return "Error: Invalid script data format. Expected JSON string."
    
    # 同步生成所有音频
    results = []
    
    for scene in scenes:
        scene_id = scene.get("scene_id")
        narration = scene.get("narration", "")
        
        if not narration:
            results.append({
                "scene_id": scene_id,
                "success": False,
                "error": "No narration text provided"
            })
            continue
        
        try:
            audio_url, audio_size = client.synthesize(
                uid=f"scene_{scene_id}",
                text=narration,
                speaker=speaker,
                audio_format="mp3",
                sample_rate=24000,
                speech_rate=speech_rate,
                loudness_rate=0
            )
            
            results.append({
                "scene_id": scene_id,
                "success": True,
                "audio_url": audio_url,
                "audio_size": audio_size,
                "narration": narration[:50] + "..." if len(narration) > 50 else narration
            })
        except Exception as e:
            results.append({
                "scene_id": scene_id,
                "success": False,
                "error": str(e)
            })
    
    # 格式化返回结果
    successful_count = sum(1 for r in results if r["success"])
    failed_scenes = [r["scene_id"] for r in results if not r["success"]]
    
    summary = {
        "total_scenes": len(scenes),
        "successful": successful_count,
        "failed": len(scenes) - successful_count,
        "failed_scene_ids": failed_scenes if failed_scenes else None,
        "audio_results": results
    }
    
    return json.dumps(summary, ensure_ascii=False, indent=2)


@tool
def get_available_speakers(runtime: ToolRuntime = None) -> str:
    """
    Get a list of available voice speakers for narration.
    
    Returns information about all available voice types with
    their characteristics and recommended use cases.
    
    Returns:
        JSON string containing speaker details including ID, name, and recommended usage
    """
    speakers = [
        {
            "speaker_id": "zh_male_dayi_saturn_bigtts",
            "name": "达意（男）",
            "category": "Video Dubbing",
            "characteristics": "专业男声，适合产品宣传、企业介绍",
            "recommended_for": "工业产品宣传视频、企业宣传片"
        },
        {
            "speaker_id": "zh_female_mizai_saturn_bigtts",
            "name": "米仔（女）",
            "category": "Video Dubbing",
            "characteristics": "专业女声，亲切自然",
            "recommended_for": "产品介绍、品牌宣传"
        },
        {
            "speaker_id": "zh_female_xiaohe_uranus_bigtts",
            "name": "小何（女）",
            "category": "General Purpose",
            "characteristics": "通用女声，清晰标准",
            "recommended_for": "一般旁白、信息播报"
        },
        {
            "speaker_id": "zh_male_m191_uranus_bigtts",
            "name": "云舟（男）",
            "category": "General Purpose",
            "characteristics": "通用男声，稳重专业",
            "recommended_for": "专业讲解、技术说明"
        },
        {
            "speaker_id": "zh_female_jitangnv_saturn_bigtts",
            "name": "鸡汤女声",
            "category": "Video Dubbing",
            "characteristics": "有感染力，适合激励性内容",
            "recommended_for": "励志宣传、品牌故事"
        }
    ]
    
    return json.dumps({
        "total_speakers": len(speakers),
        "speakers": speakers,
        "note": "紧固件宣传视频建议使用 zh_male_dayi_saturn_bigtts（达意）或 zh_male_m191_uranus_bigtts（云舟）"
    }, ensure_ascii=False, indent=2)
