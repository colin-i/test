#!/usr/bin/python3
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GdkPixbuf, cairo

import webcolors

def closest_color_name(rgb):
    try:
        return webcolors.rgb_to_name(rgb)
    except ValueError:
        # fallback to nearest
        min_dist = float('inf')
        closest = None
        for name, hexval in webcolors.CSS3_NAMES_TO_HEX.items():
            r, g, b = webcolors.hex_to_rgb(hexval)
            dist = (r - rgb[0])**2 + (g - rgb[1])**2 + (b - rgb[2])**2
            if dist < min_dist:
                min_dist = dist
                closest = name
        return closest

class ScreenshotColorPicker(Gtk.Window):
    def __init__(self, image_path):
        super().__init__()
        self.set_title("Screenshot Color Picker")
        self.set_default_size(800, 600)
        self.set_resizable(True)

        # Close GTK loop when window is closed
        self.connect("delete-event", Gtk.main_quit)

        # Load screenshot
        self.pixbuf = GdkPixbuf.Pixbuf.new_from_file(image_path)
        self.zoom_size = 10  # pixels around cursor for zoom

        # Layout
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        self.add(vbox)

        # Drawing area to show screenshot
        self.drawing_area = Gtk.DrawingArea()
        self.drawing_area.set_size_request(self.pixbuf.get_width(), self.pixbuf.get_height())
        self.drawing_area.connect("draw", self.on_draw)
        self.drawing_area.add_events(Gdk.EventMask.POINTER_MOTION_MASK | Gdk.EventMask.BUTTON_PRESS_MASK)
        self.drawing_area.connect("motion-notify-event", self.on_motion)
        self.drawing_area.connect("button-press-event", self.on_click)
        vbox.pack_start(self.drawing_area, True, True, 0)

        # Info: hex + name
        self.hex_label = Gtk.Label(label="Hex: #000000")
        vbox.pack_start(self.hex_label, False, False, 2)
        self.name_label = Gtk.Label(label="Name: black")
        vbox.pack_start(self.name_label, False, False, 2)

        # Zoom preview
        self.zoom_area = Gtk.DrawingArea()
        self.zoom_area.set_size_request(200, 200)
        self.zoom_area.connect("draw", self.on_zoom_draw)
        vbox.pack_start(self.zoom_area, False, False, 2)
        self.zoom_pixbuf = None

        self.show_all()

    def on_draw(self, widget, cr):
        # Draw the screenshot
        Gdk.cairo_set_source_pixbuf(cr, self.pixbuf, 0, 0)
        cr.paint()

    def on_motion(self, widget, event):
        self.update_pixel(event.x, event.y)

    def update_pixel(self, x, y):
        # Map mouse coordinates to image
        dw = self.drawing_area.get_allocated_width()
        dh = self.drawing_area.get_allocated_height()
        scale_x = self.pixbuf.get_width() / dw
        scale_y = self.pixbuf.get_height() / dh

        img_x = int(x * scale_x)
        img_y = int(y * scale_y)

        # Clamp inside image
        img_x = max(0, min(img_x, self.pixbuf.get_width() - 1))
        img_y = max(0, min(img_y, self.pixbuf.get_height() - 1))

        # Get pixel RGB
        pixels = self.pixbuf.get_pixels()
        rowstride = self.pixbuf.get_rowstride()
        n_channels = self.pixbuf.get_n_channels()
        offset = img_y * rowstride + img_x * n_channels
        r = pixels[offset]
        g = pixels[offset + 1]
        b = pixels[offset + 2]

        # Update labels
        self.hex_label.set_text(f"Hex: #{r:02x}{g:02x}{b:02x}")
        self.name_label.set_text(f"Name: {closest_color_name((r, g, b))}")

        # Determine subpixbuf area, clamp to edges
        x0 = max(0, img_x - self.zoom_size // 2)
        y0 = max(0, img_y - self.zoom_size // 2)
        width = min(self.zoom_size, self.pixbuf.get_width() - x0)
        height = min(self.zoom_size, self.pixbuf.get_height() - y0)

        self.zoom_pixbuf = self.pixbuf.new_subpixbuf(x0, y0, width, height)
        self.zoom_pixbuf = self.zoom_pixbuf.scale_simple(200, 200, GdkPixbuf.InterpType.NEAREST)
        self.zoom_area.queue_draw()

    def on_zoom_draw(self, widget, cr):
        if self.zoom_pixbuf:
            Gdk.cairo_set_source_pixbuf(cr, self.zoom_pixbuf, 0, 0)
            cr.paint()
        # Draw crosshair
        cr.set_source_rgba(1, 1, 1, 1)
        cr.set_line_width(2)
        cr.move_to(100, 0)
        cr.line_to(100, 200)
        cr.move_to(0, 100)
        cr.line_to(200, 100)
        cr.stroke()

    def on_click(self, widget, event):
        # Copy current hex color to clipboard
        clipboard = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD)
        clipboard.set_text(self.hex_label.get_text().split()[1], -1)
        print(f"Copied {self.hex_label.get_text().split()[1]} to clipboard")

if __name__ == "__main__":
    import sys
    if len(sys.argv) < 2:
        print("Usage: python3 pick_screenshot.py <screenshot.png>")
        exit(1)

    ScreenshotColorPicker(sys.argv[1])
    Gtk.main()
