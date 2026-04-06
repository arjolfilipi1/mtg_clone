"""
MTG Clone — Card Editor
========================
Requires: pip install PyQt5

Run:  python card_editor.py

Expects card_options.json and card.json in the same folder,
or set CARD_JSON / OPTIONS_JSON paths below.
"""

import sys, json, os, copy
from PyQt5.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QGridLayout, QLabel, QLineEdit, QSpinBox, QComboBox, QPushButton,
    QListWidget, QListWidgetItem, QGroupBox, QScrollArea, QCheckBox,
    QTabWidget, QSplitter, QMessageBox, QFileDialog, QFrame,
    QSizePolicy, QAbstractItemView
)
from PyQt5.QtCore import Qt, pyqtSignal
from PyQt5.QtGui import QFont, QColor

# ── Paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR   = os.path.dirname(os.path.abspath(__file__))
CARD_JSON    = os.path.join(SCRIPT_DIR, "card.json")
OPTIONS_JSON = os.path.join(SCRIPT_DIR, "card_options.json")

COLORS = ["red","blue","green","earth","white","black"]
COLOR_HEX = {
    "red":   "#c0392b", "blue":  "#2980b9", "green": "#27ae60",
    "earth": "#8d6e3a", "white": "#bdc3c7", "black": "#2c2c2c",
    "generic": "#7f8c8d",
}

# ── Helpers ───────────────────────────────────────────────────────────────────

def load_json(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

def save_json(path, data):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

def labeled(text, widget):
    row = QHBoxLayout()
    lbl = QLabel(text)
    lbl.setFixedWidth(110)
    row.addWidget(lbl)
    row.addWidget(widget)
    w = QWidget(); w.setLayout(row)
    return w

def separator():
    line = QFrame()
    line.setFrameShape(QFrame.HLine)
    line.setFrameShadow(QFrame.Sunken)
    return line

# ── Action editor widget ───────────────────────────────────────────────────────

class ActionEditor(QWidget):
    removed = pyqtSignal(object)

    def __init__(self, options, action_data=None, parent=None):
        super().__init__(parent)
        self.options = options
        self._build(action_data or {})

    def _build(self, d):
        layout = QVBoxLayout(self)
        layout.setContentsMargins(6, 6, 6, 6)
        self.setStyleSheet("background:#2b2b2b; border-radius:4px;")

        # Type
        top = QHBoxLayout()
        self.type_cb = QComboBox()
        for a in self.options["action_types"]:
            self.type_cb.addItem(a["label"], a["value"])
        idx = next((i for i,a in enumerate(self.options["action_types"])
                    if a["value"] == d.get("type","")), 0)
        self.type_cb.setCurrentIndex(idx)
        self.type_cb.currentIndexChanged.connect(self._refresh_fields)

        remove_btn = QPushButton("✕")
        remove_btn.setFixedWidth(28)
        remove_btn.setStyleSheet("color:#e74c3c; font-weight:bold;")
        remove_btn.clicked.connect(lambda: self.removed.emit(self))

        top.addWidget(QLabel("Action:"))
        top.addWidget(self.type_cb, 1)
        top.addWidget(remove_btn)
        layout.addLayout(top)

        # Dynamic fields
        self.fields_widget = QWidget()
        self.fields_layout = QGridLayout(self.fields_widget)
        self.fields_layout.setContentsMargins(0,0,0,0)
        layout.addWidget(self.fields_widget)

        # Store initial data for field population
        self._init_data = d
        self._refresh_fields()

    def _refresh_fields(self):
        # Clear
        for i in reversed(range(self.fields_layout.count())):
            self.fields_layout.itemAt(i).widget().deleteLater()

        action_type = self.type_cb.currentData()
        meta = next((a for a in self.options["action_types"]
                     if a["value"] == action_type), {})
        fields = meta.get("fields", [])
        d = self._init_data

        row = 0
        self._field_widgets = {}

        if "target" in fields:
            lbl = QLabel("Target:")
            cb = QComboBox()
            for t in self.options["targets"]:
                cb.addItem(t["label"], t["value"])
            idx = next((i for i,t in enumerate(self.options["targets"])
                        if t["value"] == d.get("target","self")), 0)
            cb.setCurrentIndex(idx)
            self.fields_layout.addWidget(lbl, row, 0)
            self.fields_layout.addWidget(cb, row, 1)
            self._field_widgets["target"] = cb
            row += 1

        if "amount" in fields:
            lbl = QLabel("Amount:")
            sp = QSpinBox(); sp.setRange(-999, 999)
            sp.setValue(d.get("amount", 1))
            self.fields_layout.addWidget(lbl, row, 0)
            self.fields_layout.addWidget(sp, row, 1)
            self._field_widgets["amount"] = sp
            row += 1

        if "power" in fields:
            lbl = QLabel("Power Δ:")
            sp = QSpinBox(); sp.setRange(-999, 999)
            sp.setValue(d.get("power", 0))
            self.fields_layout.addWidget(lbl, row, 0)
            self.fields_layout.addWidget(sp, row, 1)
            self._field_widgets["power"] = sp
            row += 1

        if "toughness" in fields:
            lbl = QLabel("Toughness Δ:")
            sp = QSpinBox(); sp.setRange(-999, 999)
            sp.setValue(d.get("toughness", 0))
            self.fields_layout.addWidget(lbl, row, 0)
            self.fields_layout.addWidget(sp, row, 1)
            self._field_widgets["toughness"] = sp
            row += 1

        if "duration" in fields:
            lbl = QLabel("Duration:")
            cb = QComboBox()
            for dur in self.options["durations"]:
                cb.addItem(dur["label"], dur["value"])
            idx = next((i for i,dur in enumerate(self.options["durations"])
                        if dur["value"] == d.get("duration","instant")), 0)
            cb.setCurrentIndex(idx)
            self.fields_layout.addWidget(lbl, row, 0)
            self.fields_layout.addWidget(cb, row, 1)
            self._field_widgets["duration"] = cb
            row += 1

        self._init_data = {}  # only use init data once

    def get_data(self):
        d = {"type": self.type_cb.currentData()}
        for key, widget in self._field_widgets.items():
            if isinstance(widget, QSpinBox):
                d[key] = widget.value()
            elif isinstance(widget, QComboBox):
                d[key] = widget.currentData()
        return d


# ── Effect editor widget ───────────────────────────────────────────────────────

class EffectEditor(QWidget):
    removed = pyqtSignal(object)

    def __init__(self, options, effect_data=None, parent=None):
        super().__init__(parent)
        self.options = options
        self.action_editors = []
        self._build(effect_data or {})

    def _build(self, d):
        outer = QVBoxLayout(self)
        outer.setContentsMargins(0,0,0,0)

        box = QGroupBox()
        box.setStyleSheet("QGroupBox { background:#1e1e1e; border:1px solid #444; border-radius:5px; margin-top:4px; }")
        layout = QVBoxLayout(box)

        # Header row
        header = QHBoxLayout()
        header.addWidget(QLabel("<b>Effect</b>"))
        rm = QPushButton("Remove Effect")
        rm.setStyleSheet("color:#e74c3c;")
        rm.clicked.connect(lambda: self.removed.emit(self))
        header.addStretch()
        header.addWidget(rm)
        layout.addLayout(header)
        layout.addWidget(separator())

        grid = QGridLayout()

        # Trigger
        grid.addWidget(QLabel("Trigger:"), 0, 0)
        self.trigger_cb = QComboBox()
        for t in self.options["triggers"]:
            self.trigger_cb.addItem(t["label"], t["value"])
        idx = next((i for i,t in enumerate(self.options["triggers"])
                    if t["value"] == d.get("trigger","")), 0)
        self.trigger_cb.setCurrentIndex(idx)
        self.trigger_cb.currentIndexChanged.connect(self._update_trigger_desc)
        grid.addWidget(self.trigger_cb, 0, 1)

        self.trigger_desc = QLabel("")
        self.trigger_desc.setStyleSheet("color:#888; font-size:10px;")
        self.trigger_desc.setWordWrap(True)
        grid.addWidget(self.trigger_desc, 1, 0, 1, 2)
        self._update_trigger_desc()

        # Speed
        grid.addWidget(QLabel("Speed:"), 2, 0)
        self.speed_cb = QComboBox()
        for s in self.options["speeds"]:
            self.speed_cb.addItem(s["label"], s["value"])
        idx = next((i for i,s in enumerate(self.options["speeds"])
                    if s["value"] == d.get("speed", 1)), 0)
        self.speed_cb.setCurrentIndex(idx)
        grid.addWidget(self.speed_cb, 2, 1)

        # Once per turn
        grid.addWidget(QLabel("Once per turn:"), 3, 0)
        self.once_cb = QComboBox()
        for o in self.options["once_per_turn_options"]:
            self.once_cb.addItem(o["label"], o["value"])
        idx = next((i for i,o in enumerate(self.options["once_per_turn_options"])
                    if o["value"] == d.get("once_per_turn","soft")), 0)
        self.once_cb.setCurrentIndex(idx)
        grid.addWidget(self.once_cb, 3, 1)

        # Mandatory
        grid.addWidget(QLabel("Mandatory:"), 4, 0)
        self.mandatory_cb = QCheckBox()
        self.mandatory_cb.setChecked(d.get("mandatory", False))
        grid.addWidget(self.mandatory_cb, 4, 1)

        # Description
        grid.addWidget(QLabel("Description:"), 5, 0)
        self.desc_edit = QLineEdit(d.get("description",""))
        grid.addWidget(self.desc_edit, 5, 1)

        layout.addLayout(grid)
        layout.addWidget(separator())

        # Actions
        layout.addWidget(QLabel("<b>Actions:</b>"))
        self.actions_container = QVBoxLayout()
        self.actions_container.setSpacing(4)

        for action_data in d.get("actions", []):
            self._add_action(action_data)

        add_action_btn = QPushButton("+ Add Action")
        add_action_btn.clicked.connect(lambda: self._add_action({}))
        add_action_btn.setStyleSheet("background:#2ecc71; color:black; font-weight:bold;")

        layout.addLayout(self.actions_container)
        layout.addWidget(add_action_btn)

        outer.addWidget(box)

    def _update_trigger_desc(self):
        val = self.trigger_cb.currentData()
        desc = next((t["description"] for t in self.options["triggers"]
                     if t["value"] == val), "")
        self.trigger_desc.setText(desc)

    def _add_action(self, data):
        ae = ActionEditor(self.options, data)
        ae.removed.connect(self._remove_action)
        self.action_editors.append(ae)
        self.actions_container.addWidget(ae)

    def _remove_action(self, ae):
        self.action_editors.remove(ae)
        self.actions_container.removeWidget(ae)
        ae.deleteLater()

    def get_data(self):
        return {
            "trigger":      self.trigger_cb.currentData(),
            "speed":        self.speed_cb.currentData(),
            "mandatory":    self.mandatory_cb.isChecked(),
            "once_per_turn":self.once_cb.currentData(),
            "mana_cost":    {},
            "description":  self.desc_edit.text(),
            "actions":      [ae.get_data() for ae in self.action_editors],
        }


# ── Range grid widget ──────────────────────────────────────────────────────────

class RangeGrid(QWidget):
    """6×5 grid where player is at bottom-center. Click cells to toggle."""

    ROWS = 6
    COLS = 5
    ORIGIN_ROW = 5   # bottom row = player row
    ORIGIN_COL = 2   # center column

    def __init__(self, parent=None):
        super().__init__(parent)
        self.buttons = {}
        layout = QVBoxLayout(self)
        layout.setSpacing(2)

        # Label
        title = QLabel("Attack Range  (click to toggle, 🟦 = card position)")
        title.setStyleSheet("font-size:10px; color:#aaa;")
        layout.addWidget(title)

        grid = QGridLayout()
        grid.setSpacing(2)

        for r in range(self.ROWS):
            for c in range(self.COLS):
                btn = QPushButton()
                btn.setFixedSize(34, 34)
                btn.setCheckable(True)
                btn.setStyleSheet(self._style(False))
                dr = self.ORIGIN_ROW - r
                dc = c - self.ORIGIN_COL
                if r == self.ORIGIN_ROW and c == self.ORIGIN_COL:
                    btn.setText("▶")
                    btn.setEnabled(False)
                    btn.setStyleSheet("background:#3498db; border-radius:4px; color:white;")
                else:
                    btn.setText(f"{dr},{dc}")
                    btn.setFont(QFont("", 7))
                    btn.toggled.connect(lambda checked, b=btn: b.setStyleSheet(self._style(checked)))
                self.buttons[(dr, dc)] = btn
                grid.addWidget(btn, r, c)

        layout.addLayout(grid)

        # Presets
        preset_row = QHBoxLayout()
        preset_row.addWidget(QLabel("Preset:"))
        self.preset_cb = QComboBox()
        self.preset_cb.addItem("— custom —", None)
        for name in self._presets().keys():
            self.preset_cb.addItem(name, name)
        self.preset_cb.currentIndexChanged.connect(self._apply_preset)
        preset_row.addWidget(self.preset_cb, 1)
        layout.addLayout(preset_row)

    def _style(self, active):
        if active:
            return "background:#e74c3c; border-radius:4px; color:white; font-size:7px;"
        return "background:#333; border-radius:4px; color:#888; font-size:7px;"

    def _presets(self):
        return {
            "Melee (front only)":      [[1,0]],
            "Short range":             [[1,0],[2,0],[2,1],[2,-1]],
            "Wide melee":              [[1,0],[1,1],[1,-1]],
            "Ranged (3 rows forward)": [[1,0],[2,0],[3,0],[3,-1],[3,1]],
            "Flying (large area)":     [[1,0],[2,0],[2,1],[2,-1],[1,-1],[1,1],[1,2],[1,-2],[2,2],[2,-2],[3,2],[3,1],[3,0],[3,-1],[3,-2]],
            "No range (spell)":        [],
        }

    def _apply_preset(self):
        name = self.preset_cb.currentData()
        if name is None:
            return
        self.set_range(self._presets()[name])

    def set_range(self, range_list):
        active = {tuple(r) for r in range_list}
        for (dr, dc), btn in self.buttons.items():
            if btn.isEnabled():
                btn.setChecked((dr, dc) in active)

    def get_range(self):
        return [[dr, dc] for (dr, dc), btn in self.buttons.items()
                if btn.isEnabled() and btn.isChecked()]


# ── Mana cost widget ───────────────────────────────────────────────────────────

class ManaCostWidget(QWidget):
    def __init__(self, initial=None, parent=None):
        super().__init__(parent)
        layout = QHBoxLayout(self)
        layout.setContentsMargins(0,0,0,0)
        self.spins = {}
        init = initial or {}
        for color in ["generic"] + COLORS:
            col_layout = QVBoxLayout()
            lbl = QLabel(color[:3].capitalize())
            lbl.setAlignment(Qt.AlignCenter)
            lbl.setStyleSheet(f"color:{COLOR_HEX.get(color,'#fff')}; font-size:9px;")
            sp = QSpinBox(); sp.setRange(0, 10); sp.setFixedWidth(44)
            sp.setValue(init.get(color, 0))
            col_layout.addWidget(lbl)
            col_layout.addWidget(sp)
            layout.addLayout(col_layout)
            self.spins[color] = sp

    def get_data(self):
        return {c: sp.value() for c, sp in self.spins.items()}

    def set_data(self, d):
        for c, sp in self.spins.items():
            sp.setValue(d.get(c, 0))


# ── Mana creation widget ───────────────────────────────────────────────────────

class ManaCreationWidget(QWidget):
    def __init__(self, initial=None, parent=None):
        super().__init__(parent)
        layout = QVBoxLayout(self)
        layout.setContentsMargins(0,0,0,0)

        self.entries = []
        self.list_widget = QListWidget()
        self.list_widget.setFixedHeight(70)
        layout.addWidget(self.list_widget)

        btn_row = QHBoxLayout()
        self.add_cb = QComboBox()
        for c in COLORS:
            self.add_cb.addItem(c.capitalize(), c)
        add_btn = QPushButton("Add")
        add_btn.clicked.connect(self._add)
        rm_btn = QPushButton("Remove")
        rm_btn.clicked.connect(self._remove)
        btn_row.addWidget(self.add_cb)
        btn_row.addWidget(add_btn)
        btn_row.addWidget(rm_btn)
        layout.addLayout(btn_row)

        for item in (initial or []):
            self._add_item(item)

    def _add(self):
        self._add_item(self.add_cb.currentData())

    def _add_item(self, color):
        self.entries.append(color)
        item = QListWidgetItem(color.capitalize())
        item.setBackground(QColor(COLOR_HEX.get(color, "#333")))
        item.setForeground(QColor("white"))
        self.list_widget.addItem(item)

    def _remove(self):
        row = self.list_widget.currentRow()
        if row >= 0:
            self.list_widget.takeItem(row)
            self.entries.pop(row)

    def get_data(self):
        return list(self.entries)

    def set_data(self, lst):
        self.list_widget.clear()
        self.entries.clear()
        for item in lst:
            self._add_item(item)


# ── Card editor panel ──────────────────────────────────────────────────────────

class CardEditorPanel(QWidget):
    def __init__(self, options, parent=None):
        super().__init__(parent)
        self.options = options
        self.effect_editors = []
        self._build()

    def _build(self):
        main = QHBoxLayout(self)

        # Left: basic fields
        left = QScrollArea()
        left.setWidgetResizable(True)
        left_content = QWidget()
        left_layout = QVBoxLayout(left_content)
        left_layout.setSpacing(8)

        # ── Basic info ─────────────────────────────────────────────────────────
        info_box = QGroupBox("Basic Info")
        info_lay = QGridLayout(info_box)

        info_lay.addWidget(QLabel("Name:"), 0, 0)
        self.name_edit = QLineEdit()
        info_lay.addWidget(self.name_edit, 0, 1)

        info_lay.addWidget(QLabel("Type:"), 1, 0)
        self.type_cb = QComboBox()
        for t in options["card_types"]:
            self.type_cb.addItem(t)
        self.type_cb.currentTextChanged.connect(self._on_type_changed)
        info_lay.addWidget(self.type_cb, 1, 1)

        info_lay.addWidget(QLabel("Background:"), 2, 0)
        self.bg_cb = QComboBox()
        for b in options["backgrounds"]:
            self.bg_cb.addItem(b.capitalize(), b)
        info_lay.addWidget(self.bg_cb, 2, 1)

        info_lay.addWidget(QLabel("Image file:"), 3, 0)
        self.image_edit = QLineEdit()
        img_btn = QPushButton("Browse")
        img_btn.clicked.connect(self._browse_image)
        img_row = QHBoxLayout()
        img_row.addWidget(self.image_edit)
        img_row.addWidget(img_btn)
        img_w = QWidget(); img_w.setLayout(img_row)
        info_lay.addWidget(img_w, 3, 1)

        left_layout.addWidget(info_box)

        # ── Stats ──────────────────────────────────────────────────────────────
        stats_box = QGroupBox("Stats (Creature)")
        stats_lay = QGridLayout(stats_box)
        stats_lay.addWidget(QLabel("Power:"), 0, 0)
        self.power_sp = QSpinBox(); self.power_sp.setRange(0, 9999)
        stats_lay.addWidget(self.power_sp, 0, 1)
        stats_lay.addWidget(QLabel("Toughness:"), 1, 0)
        self.tough_sp = QSpinBox(); self.tough_sp.setRange(0, 9999)
        stats_lay.addWidget(self.tough_sp, 1, 1)
        self.stats_box = stats_box
        left_layout.addWidget(stats_box)

        # ── Mana cost ──────────────────────────────────────────────────────────
        cost_box = QGroupBox("Mana Cost")
        cost_lay = QVBoxLayout(cost_box)
        self.mana_cost_w = ManaCostWidget()
        cost_lay.addWidget(self.mana_cost_w)
        left_layout.addWidget(cost_box)

        # ── Mana creation ──────────────────────────────────────────────────────
        creation_box = QGroupBox("Mana Creation (when used as mana card)")
        creation_lay = QVBoxLayout(creation_box)
        self.mana_creation_w = ManaCreationWidget()
        creation_lay.addWidget(self.mana_creation_w)
        self.creation_box = creation_box
        left_layout.addWidget(creation_box)

        left_layout.addStretch()
        left.setWidget(left_content)
        main.addWidget(left, 1)

        # Right: range + effects
        right = QScrollArea()
        right.setWidgetResizable(True)
        right_content = QWidget()
        right_layout = QVBoxLayout(right_content)
        right_layout.setSpacing(8)

        # ── Range ──────────────────────────────────────────────────────────────
        range_box = QGroupBox("Attack Range")
        range_lay = QVBoxLayout(range_box)
        self.range_grid = RangeGrid()
        range_lay.addWidget(self.range_grid)
        self.range_box = range_box
        right_layout.addWidget(range_box)

        # ── Effects ────────────────────────────────────────────────────────────
        effects_box = QGroupBox("Effects")
        effects_lay = QVBoxLayout(effects_box)
        self.effects_container = QVBoxLayout()
        self.effects_container.setSpacing(6)
        add_eff_btn = QPushButton("+ Add Effect")
        add_eff_btn.setStyleSheet("background:#8e44ad; color:white; font-weight:bold; padding:6px;")
        add_eff_btn.clicked.connect(lambda: self._add_effect({}))
        effects_lay.addLayout(self.effects_container)
        effects_lay.addWidget(add_eff_btn)
        right_layout.addWidget(effects_box)

        right_layout.addStretch()
        right.setWidget(right_content)
        main.addWidget(right, 1)

        self._on_type_changed(self.type_cb.currentText())

    def _on_type_changed(self, card_type):
        is_creature = card_type == "Creature"
        self.stats_box.setVisible(True)   # always show for now
        self.range_box.setVisible(is_creature)
        self.creation_box.setVisible(True)

    def _browse_image(self):
        path, _ = QFileDialog.getOpenFileName(self, "Select Image", "", "Images (*.png *.jpg *.jpeg)")
        if path:
            self.image_edit.setText(os.path.basename(path))

    def _add_effect(self, data):
        ee = EffectEditor(self.options, data)
        ee.removed.connect(self._remove_effect)
        self.effect_editors.append(ee)
        self.effects_container.addWidget(ee)

    def _remove_effect(self, ee):
        self.effect_editors.remove(ee)
        self.effects_container.removeWidget(ee)
        ee.deleteLater()

    def load_card(self, card):
        self.name_edit.setText(card.get("name", ""))

        ct = card.get("type", "Creature")
        idx = self.type_cb.findText(ct)
        if idx >= 0: self.type_cb.setCurrentIndex(idx)

        bg = card.get("background", "red")
        idx = self.bg_cb.findData(bg)
        if idx >= 0: self.bg_cb.setCurrentIndex(idx)

        self.image_edit.setText(card.get("image", ""))
        self.power_sp.setValue(card.get("power", 0))
        self.tough_sp.setValue(card.get("toughness", 0))
        self.mana_cost_w.set_data(card.get("mana_cost", {}))
        self.mana_creation_w.set_data(card.get("Mana_creation", []))
        self.range_grid.set_range(card.get("range", []))

        # Clear and reload effects
        for ee in list(self.effect_editors):
            self._remove_effect(ee)
        for eff in card.get("effects", []):
            self._add_effect(eff)

    def get_card_data(self, card_id):
        return {
            "id":           card_id,
            "name":         self.name_edit.text().strip(),
            "type":         self.type_cb.currentText(),
            "background":   self.bg_cb.currentData(),
            "image":        self.image_edit.text().strip(),
            "power":        self.power_sp.value(),
            "toughness":    self.tough_sp.value(),
            "mana_cost":    self.mana_cost_w.get_data(),
            "Mana_creation":self.mana_creation_w.get_data(),
            "range":        self.range_grid.get_range(),
            "effects":      [ee.get_data() for ee in self.effect_editors],
        }


# ── Main window ────────────────────────────────────────────────────────────────

class CardEditorWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("MTG Clone — Card Editor")
        self.resize(1200, 800)
        self.options  = load_json(OPTIONS_JSON)
        self.cards    = load_json(CARD_JSON)
        self.current_idx = None
        self._apply_dark_theme()
        self._build_ui()
        self._populate_list()

    def _apply_dark_theme(self):
        self.setStyleSheet("""
            QMainWindow, QWidget { background:#1a1a1a; color:#ddd; }
            QGroupBox { border:1px solid #444; border-radius:5px; margin-top:8px; padding:8px; }
            QGroupBox::title { subcontrol-origin:margin; left:8px; color:#aaa; }
            QLineEdit, QSpinBox, QComboBox { background:#2b2b2b; border:1px solid #555;
                border-radius:3px; padding:3px; color:#eee; }
            QPushButton { background:#333; border:1px solid #555; border-radius:3px;
                padding:4px 10px; color:#eee; }
            QPushButton:hover { background:#444; }
            QListWidget { background:#111; border:1px solid #333; }
            QListWidget::item:selected { background:#2980b9; }
            QScrollArea { border:none; }
            QCheckBox { color:#ddd; }
            QLabel { color:#ccc; }
        """)

    def _build_ui(self):
        central = QWidget()
        self.setCentralWidget(central)
        main_layout = QHBoxLayout(central)

        # ── Left sidebar: card list ────────────────────────────────────────────
        sidebar = QVBoxLayout()
        sidebar.addWidget(QLabel("<b>Cards</b>"))

        self.card_list = QListWidget()
        self.card_list.setFixedWidth(200)
        self.card_list.currentRowChanged.connect(self._on_card_selected)
        sidebar.addWidget(self.card_list)

        btn_row = QHBoxLayout()
        new_btn = QPushButton("New")
        new_btn.setStyleSheet("background:#27ae60; color:white; font-weight:bold;")
        new_btn.clicked.connect(self._new_card)
        dup_btn = QPushButton("Duplicate")
        dup_btn.clicked.connect(self._duplicate_card)
        btn_row.addWidget(new_btn)
        btn_row.addWidget(dup_btn)
        sidebar.addLayout(btn_row)

        del_btn = QPushButton("Delete Card")
        del_btn.setStyleSheet("background:#c0392b; color:white;")
        del_btn.clicked.connect(self._delete_card)
        sidebar.addWidget(del_btn)

        sidebar_w = QWidget()
        sidebar_w.setLayout(sidebar)
        sidebar_w.setFixedWidth(210)
        main_layout.addWidget(sidebar_w)

        # ── Editor area ────────────────────────────────────────────────────────
        self.editor = CardEditorPanel(self.options)
        main_layout.addWidget(self.editor, 1)

        # ── Bottom bar ─────────────────────────────────────────────────────────
        bottom = QVBoxLayout()
        bottom.addStretch()
        save_btn = QPushButton("💾  Save All to card.json")
        save_btn.setStyleSheet("background:#2980b9; color:white; font-weight:bold; padding:8px 20px; font-size:13px;")
        save_btn.clicked.connect(self._save)
        bottom.addWidget(save_btn)

        right_col = QVBoxLayout()
        right_col.addLayout(bottom)

        container = QVBoxLayout()
        container.addWidget(self.editor)
        container.addWidget(save_btn)

        main_layout.removeWidget(self.editor)
        right_w = QWidget()
        right_w.setLayout(container)
        main_layout.addWidget(right_w, 1)

    def _populate_list(self):
        self.card_list.clear()
        for card in self.cards:
            self.card_list.addItem(f"[{card['id']}] {card['name']}")
        if self.cards:
            self.card_list.setCurrentRow(0)

    def _on_card_selected(self, row):
        if 0 <= row < len(self.cards):
            self.current_idx = row
            self.editor.load_card(self.cards[row])

    def _save_current_to_memory(self):
        """Push editor state back into self.cards without saving to disk."""
        if self.current_idx is None:
            return
        card_id = self.cards[self.current_idx]["id"]
        self.cards[self.current_idx] = self.editor.get_card_data(card_id)
        name = self.cards[self.current_idx]["name"] or "(unnamed)"
        self.card_list.item(self.current_idx).setText(f"[{card_id}] {name}")

    def _new_card(self):
        self._save_current_to_memory()
        new_id = max((c["id"] for c in self.cards), default=0) + 1
        blank = {
            "id": new_id, "name": "New Card", "type": "Creature",
            "mana_cost": {c:0 for c in ["generic"]+COLORS},
            "effects": [], "background": "red", "power": 10,
            "image": "", "toughness": 10, "Mana_creation": [], "range": [[1,0]],
        }
        self.cards.append(blank)
        self._populate_list()
        self.card_list.setCurrentRow(len(self.cards)-1)

    def _duplicate_card(self):
        if self.current_idx is None:
            return
        self._save_current_to_memory()
        src = copy.deepcopy(self.cards[self.current_idx])
        src["id"] = max(c["id"] for c in self.cards) + 1
        src["name"] = src["name"] + " (copy)"
        self.cards.append(src)
        self._populate_list()
        self.card_list.setCurrentRow(len(self.cards)-1)

    def _delete_card(self):
        if self.current_idx is None:
            return
        name = self.cards[self.current_idx]["name"]
        reply = QMessageBox.question(self, "Delete", f"Delete '{name}'?",
                                     QMessageBox.Yes | QMessageBox.No)
        if reply == QMessageBox.Yes:
            self.cards.pop(self.current_idx)
            self.current_idx = None
            self._populate_list()
            if self.cards:
                self.card_list.setCurrentRow(0)

    def _save(self):
        self._save_current_to_memory()
        # Validate
        for card in self.cards:
            if not card.get("name","").strip():
                QMessageBox.warning(self, "Validation", f"Card ID {card['id']} has no name.")
                return
        save_json(CARD_JSON, self.cards)
        QMessageBox.information(self, "Saved", f"Saved {len(self.cards)} cards to:\n{CARD_JSON}")


# ── Entry point ────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    app = QApplication(sys.argv)
    app.setFont(QFont("Segoe UI", 9))
    win = CardEditorWindow()
    win.show()
    sys.exit(app.exec_())
