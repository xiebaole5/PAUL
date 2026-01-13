from langchain.tools import tool, ToolRuntime
from coze_coding_dev_sdk import ImageGenerationClient
from coze_coding_utils.runtime_ctx.context import new_context
import os


@tool
def generate_video_scene_image(
    visual_description: str, 
    scene_number: int,
    size: str = "2K",
    runtime: ToolRuntime = None
) -> str:
    """
    Generate an image for a video scene based on visual description.
    
    This tool uses AI image generation to create high-quality images
    suitable for fastener promotional videos. The images will be
    automatically uploaded to object storage and return accessible URLs.
    
    Args:
        visual_description: Detailed description of the scene (e.g., "高清镜头展示高强度螺栓的精密制造过程，工业流水线场景")
        scene_number: Scene identifier (used for image filename)
        size: Image resolution - "2K" or "4K" (default: "2K")
    
    Returns:
        Image URL from object storage (e.g., "https://storage.example.com/images/scene_1.png")
    """
    ctx = new_context(method="generate_video_scene_image")
    
    client = ImageGenerationClient(ctx=ctx)
    
    # 优化提示词，确保生成的图片适合工业产品宣传
    optimized_prompt = f"""Professional industrial product photography, {visual_description}.

Style requirements:
- High quality, professional lighting
- Clean industrial environment
- Focus on product details and quality
- Modern manufacturing setting
- Sharp focus, cinematic composition
- Photorealistic, 8K quality"""

    response = client.generate(
        prompt=optimized_prompt,
        size=size,
        watermark=False,  # 宣传视频通常不需要水印
        response_format="url"
    )
    
    if response.success and response.image_urls:
        image_url = response.image_urls[0]
        return f"Scene {scene_number} image generated successfully: {image_url}"
    else:
        error_msg = ", ".join(response.error_messages) if response.error_messages else "Unknown error"
        return f"Failed to generate image for scene {scene_number}: {error_msg}"


@tool
def generate_multiple_scenes_images(visual_descriptions: list, size: str = "2K", runtime: ToolRuntime = None) -> str:
    """
    Generate multiple images for multiple video scenes in batch.
    
    This tool is more efficient when you need to generate images
    for several scenes at once. It processes all visual descriptions
    and returns a list of image URLs.
    
    Args:
        visual_descriptions: List of visual descriptions for each scene
        size: Image resolution - "2K" or "4K" (default: "2K")
    
    Returns:
        JSON string containing scene numbers and corresponding image URLs
    """
    import asyncio
    import json
    
    ctx = new_context(method="generate_multiple_scenes_images")
    
    client = ImageGenerationClient(ctx=ctx)
    
    async def generate_single_image(desc: str, index: int):
        optimized_prompt = f"""Professional industrial product photography, {desc}.

Style requirements:
- High quality, professional lighting
- Clean industrial environment
- Focus on product details and quality
- Modern manufacturing setting
- Sharp focus, cinematic composition
- Photorealistic, 8K quality"""
        
        response = await client.generate_async(
            prompt=optimized_prompt,
            size=size,
            watermark=False,
            response_format="url"
        )
        
        return {
            "scene_id": index + 1,
            "success": response.success,
            "image_url": response.image_urls[0] if response.success and response.image_urls else None,
            "error": ", ".join(response.error_messages) if not response.success else None
        }
    
    # 异步并行生成所有图片
    async def generate_all():
        tasks = [
            generate_single_image(desc, idx) 
            for idx, desc in enumerate(visual_descriptions)
        ]
        return await asyncio.gather(*tasks)
    
    results = asyncio.run(generate_all())
    
    # 格式化返回结果
    successful_count = sum(1 for r in results if r["success"])
    failed_scenes = [r["scene_id"] for r in results if not r["success"]]
    
    summary = {
        "total_scenes": len(visual_descriptions),
        "successful": successful_count,
        "failed": len(visual_descriptions) - successful_count,
        "failed_scene_ids": failed_scenes if failed_scenes else None,
        "results": results
    }
    
    return json.dumps(summary, ensure_ascii=False, indent=2)
