import GLib from 'gi://GLib';
import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';

export default class FocusWatchExtension extends Extension {
    constructor(metadata) {
        super(metadata);
        this._handler = null;
    }

    // Helper to print logs
    _log(msg) {
            console.log(`[FocusWatch] ${msg}`);
    }

    _onFocusChanged() {
        let win = global.display.focus_window;

        if (!win)
            return;

        let title = win.get_title();

        if (title)
            this._log(title);
    }

    enable() {
        // In ESM classes, you track your state on `this`
        this._handler = global.display.connect(
            'notify::focus-window',
            () => this._onFocusChanged()
        );
    }

    disable() {
        if (this._handler) {
            global.display.disconnect(this._handler);
            this._handler = null;
        }
    }
}
