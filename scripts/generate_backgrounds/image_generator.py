"""
Image generator using Pollinations.ai (free, no API key required).

Generates images with retry logic and quality review.
"""

import time
import urllib.parse
from pathlib import Path
from typing import Optional
import httpx

from .config import (
    POLLINATIONS_BASE_URL,
    IMAGE_WIDTH,
    IMAGE_HEIGHT,
    MAX_RETRIES,
    RETRY_DELAY_SECONDS,
    STYLE_BLOCK,
    BACKGROUNDS_DIR,
)
# Review is now done by Claude, not automatically
# from .image_reviewer import review_image, format_review_report


def build_image_url(prompt: str, seed: Optional[int] = None) -> str:
    """Build Pollinations.ai URL from prompt."""
    # Clean up prompt - remove newlines, extra spaces
    clean_prompt = " ".join(prompt.split())
    encoded_prompt = urllib.parse.quote(clean_prompt)

    url = f"{POLLINATIONS_BASE_URL}/{encoded_prompt}?width={IMAGE_WIDTH}&height={IMAGE_HEIGHT}&nologo=true"

    if seed is not None:
        url += f"&seed={seed}"

    return url


def generate_image(
    prompt: str,
    output_path: Path,
    seed: Optional[int] = None,
    timeout: int = 180
) -> bool:
    """
    Generate a single image from prompt.

    Returns True if successful, False otherwise.
    """
    url = build_image_url(prompt, seed)

    try:
        print(f"  🎨 Generating image...")
        print(f"  📍 Seed: {seed or 'random'}")

        response = httpx.get(url, timeout=timeout, follow_redirects=True)
        response.raise_for_status()

        # Verify we got an image
        content_type = response.headers.get("content-type", "")
        if "image" not in content_type and len(response.content) < 10000:
            print(f"  ❌ Invalid response: {content_type}, {len(response.content)} bytes")
            return False

        # Save image
        output_path.parent.mkdir(parents=True, exist_ok=True)
        with open(output_path, "wb") as f:
            f.write(response.content)

        file_size_kb = len(response.content) / 1024
        print(f"  ✅ Saved: {output_path.name} ({file_size_kb:.1f} KB)")
        return True

    except httpx.TimeoutException:
        print(f"  ❌ Timeout after {timeout}s")
        return False
    except Exception as e:
        print(f"  ❌ Error: {e}")
        return False


def generate_with_review(
    prompt: str,
    output_path: Path,
    location_name: str,
    country: str,
    expected_foods: list[str],
    expected_drinks: list[str],
    expected_landmarks: list[str],
    max_attempts: int = MAX_RETRIES,
    base_seed: int = 100,
) -> dict:
    """
    Generate image with quality review. Retry if rejected.

    Returns:
        dict with:
            - success: bool
            - attempts: int
            - final_review: dict
            - output_path: Path (if successful)
            - all_reviews: list of all review attempts
    """
    all_reviews = []

    for attempt in range(1, max_attempts + 1):
        seed = base_seed + (attempt - 1) * 111  # Vary seed each attempt

        print(f"\n{'='*60}")
        print(f"  ATTEMPT {attempt}/{max_attempts} for {location_name}")
        print(f"{'='*60}")

        # Generate image
        attempt_path = output_path.with_stem(f"{output_path.stem}_attempt{attempt}")
        success = generate_image(prompt, attempt_path, seed=seed)

        if not success:
            print(f"  ⚠️  Generation failed, retrying...")
            time.sleep(RETRY_DELAY_SECONDS)
            continue

        # Review image
        print(f"  🔍 Reviewing image quality...")
        review = review_image(
            image_path=attempt_path,
            location_name=location_name,
            country=country,
            expected_foods=expected_foods,
            expected_drinks=expected_drinks,
            expected_landmarks=expected_landmarks,
        )

        all_reviews.append({
            "attempt": attempt,
            "seed": seed,
            "review": review,
            "path": str(attempt_path)
        })

        print(format_review_report(review, location_name))

        if review["approved"]:
            # Rename to final output path
            if attempt_path != output_path:
                attempt_path.rename(output_path)
                # Clean up other attempts
                for old_attempt in output_path.parent.glob(f"{output_path.stem}_attempt*"):
                    old_attempt.unlink()

            return {
                "success": True,
                "attempts": attempt,
                "final_review": review,
                "output_path": output_path,
                "all_reviews": all_reviews
            }

        print(f"  🔄 Image rejected, {'retrying' if attempt < max_attempts else 'max attempts reached'}...")

        if attempt < max_attempts:
            # Modify prompt based on feedback if available
            suggestions = review.get("suggestions", [])
            if suggestions:
                print(f"  💡 Will adjust based on: {suggestions[0][:50]}...")
            time.sleep(RETRY_DELAY_SECONDS)

    # All attempts failed - pick the best one
    if all_reviews:
        best = max(all_reviews, key=lambda x: x["review"].get("score", 0))
        best_path = Path(best["path"])
        if best_path.exists() and best_path != output_path:
            best_path.rename(output_path)
            # Clean up other attempts
            for old_attempt in output_path.parent.glob(f"{output_path.stem}_attempt*"):
                old_attempt.unlink()

        print(f"\n  ⚠️  Using best attempt (score: {best['review'].get('score', 'N/A')})")

        return {
            "success": False,
            "attempts": max_attempts,
            "final_review": best["review"],
            "output_path": output_path if output_path.exists() else None,
            "all_reviews": all_reviews,
            "note": "Used best available despite not meeting quality threshold"
        }

    return {
        "success": False,
        "attempts": max_attempts,
        "final_review": None,
        "output_path": None,
        "all_reviews": all_reviews
    }


if __name__ == "__main__":
    # Test generation
    test_prompt = """
    A Studio Ghibli inspired travel illustration of Tokyo Japan,
    FOREGROUND food focus monjayaki sizzling on hot iron griddle
    and steaming chanko nabe sumo hot pot and bright green melon cream soda,
    MIDGROUND Shibuya Scramble Crossing with silhouettes crossing,
    BACKGROUND Tokyo Tower and neon billboards and red paper lanterns,
    NO hands NO feet NO fingers NO faces,
    soft watercolor textures, golden hour lighting, 16x9 cinematic
    """

    output = BACKGROUNDS_DIR / "test_tokyo.png"

    result = generate_with_review(
        prompt=test_prompt,
        output_path=output,
        location_name="Tokyo",
        country="Japan",
        expected_foods=["Monjayaki", "Chanko Nabe"],
        expected_drinks=["Melon Cream Soda", "Hoppy"],
        expected_landmarks=["Tokyo Tower", "Shibuya Crossing"],
        max_attempts=2
    )

    print(f"\nFinal result: {'✅ Success' if result['success'] else '❌ Failed'}")
    print(f"Attempts: {result['attempts']}")
    if result["output_path"]:
        print(f"Output: {result['output_path']}")
