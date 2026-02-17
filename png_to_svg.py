import sys
import time
import os
import base64
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
from PIL import Image

class ImageHandler(FileSystemEventHandler):
    def on_created(self, event):
        if not event.is_directory and event.src_path.lower().endswith(".png"):
            print(f"检测到新文件: {event.src_path}")
            # 等待文件完全写入，避免读取不完整
            time.sleep(0.5)
            try:
                convert_to_svg(event.src_path)
            except Exception as e:
                print(f"转换失败 {event.src_path}: {e}")

def convert_to_svg(png_path):
    svg_path = os.path.splitext(png_path)[0] + ".svg"
    
    # 简单的转换逻辑：将 PNG 作为 base64 嵌入 SVG
    # 如果你需要矢量化（路径描边），可以使用 vtracer 或 potrace 库
    with Image.open(png_path) as img:
        width, height = img.size
        
    with open(png_path, "rb") as image_file:
        encoded_string = base64.b64encode(image_file.read()).decode()
        
    svg_content = f'''<svg width="{width}" height="{height}" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
    <image href="data:image/png;base64,{encoded_string}" width="{width}" height="{height}" x="0" y="0" />
</svg>'''
    
    with open(svg_path, "w", encoding="utf-8") as f:
        f.write(svg_content)
        
    print(f"已生成 SVG: {svg_path}")

if __name__ == "__main__":
    # 默认为当前目录，也可以通过参数指定
    path = sys.argv[1] if len(sys.argv) > 1 else "."
    
    event_handler = ImageHandler()
    observer = Observer()
    observer.schedule(event_handler, path, recursive=False)
    observer.start()
    
    print(f"正在监控文件夹: {os.path.abspath(path)}")
    print("请放入 PNG 图片...")
    
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()
