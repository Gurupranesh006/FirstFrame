from pathlib import Path
from datetime import datetime
import importlib


BASE_DIR = Path(__file__).resolve().parent
OUTPUT_DIR = BASE_DIR / "startup_photos"
LOG_FILE = BASE_DIR / "startup_log.txt"


def ensure_paths() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


def log_start_time(now: datetime) -> None:
    with LOG_FILE.open("a", encoding="utf-8") as file:
        file.write(f"STARTED: {now.strftime('%Y-%m-%d %H:%M:%S')}\n")


def take_photo(now: datetime) -> Path | None:
    try:
        cv2 = importlib.import_module("cv2")
    except ModuleNotFoundError:
        with LOG_FILE.open("a", encoding="utf-8") as file:
            file.write("PHOTO_ERROR: opencv-python is not installed\n")
        return None

    filename = f"{now.strftime('%Y-%m-%d_%H-%M-%S')}.jpg"
    photo_path = OUTPUT_DIR / filename

    camera = cv2.VideoCapture(0, cv2.CAP_DSHOW)
    if not camera.isOpened():
        with LOG_FILE.open("a", encoding="utf-8") as file:
            file.write("PHOTO_ERROR: Camera not available\n")
        return None

    for _ in range(5):
        camera.read()

    success, frame = camera.read()
    camera.release()

    if not success:
        with LOG_FILE.open("a", encoding="utf-8") as file:
            file.write("PHOTO_ERROR: Failed to read frame\n")
        return None

    cv2.imwrite(str(photo_path), frame)
    with LOG_FILE.open("a", encoding="utf-8") as file:
        file.write(f"PHOTO_SAVED: {photo_path.name}\n")

    return photo_path


def main() -> None:
    now = datetime.now()
    ensure_paths()
    log_start_time(now)
    take_photo(now)


if __name__ == "__main__":
    main()
