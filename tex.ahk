#Requires AutoHotkey v2.0

;---
; 記号マップ
;---
symbolMap := Map(
    "alpha",   "α",
    "beta",    "β",
    "gamma",   "γ",
    "delta",   "δ",
    "epsilon", "ε",
    "zeta",    "ζ",
    "eta",     "η",
    "theta",   "θ",
    "iota",    "ι",
    "kappa",   "κ",
    "lambda",  "λ",
    "mu",      "μ",
    "nu",      "ν",
    "xi",      "ξ",
    "omicron", "ο",
    "pi",      "π",
    "rho",     "ρ",
    "sigma",   "σ",
    "tau",     "τ",
    "upsilon", "υ",
    "phi",     "φ",
    "chi",     "χ",
    "psi",     "ψ",
    "omega",   "ω",
    "sum",     "∑",
    "prod",    "∏",
    "int",     "∫",
    "oplus",   "⊕",
    "otimes",  "⊗",
    "in",      "∈",
    "subset",  "⊂",
    "cap",     "∩",
    "cup",     "∪",
    "neq",     "≠",
    "cong",    "≅",
    "forall",  "∀",
    "exists",  "∃",
    "infty",   "∞",
    "pm",      "±",
    "circ",    "∘",
    "perp",    "⊥",
    "daskv",   "⊣",
;    "","",
)

; 現在入力中の文字列、候補リスト、選択中インデックス
currentInput := ""
suggestions  := []
selectedIndex := 1

; Ctrl+T でサジェストモード開始
^t:: {
    global currentInput, suggestions, selectedIndex

    ; 初期化
    currentInput := ""
    suggestions  := []
    selectedIndex := 1

    ; InputHook(Options, EndKeys, MatchList)
    ; "V"= ユーザーの入力はブロックせず、アクティブウィンドウに送る
    ; Enter/Esc を終了キーにする
    ih := InputHook("S", "{Escape}{Enter}")

    ; "S"= 入力ウィンドウには渡さない
    ; "I"= 非テキストとして扱う
    ; "N"= OnKeyDown が呼び出される
    ih.KeyOpt("{Enter}", "S")
    ih.KeyOpt("{Tab}", "INS")
    ih.KeyOpt("{Backspace}", "NS")

    ih.OnChar := OnChar
    ih.OnKeyDown := OnVKey
    ih.OnEnd := OnEnd

    ; モード開始
    ih.Start()
    ToolTip "記号サジェストモード"
}

;---
; ユーザーが入力した文字が渡されるたびに呼ばれる
;---
OnChar(ih, char) {
    global symbolMap, currentInput, suggestions, selectedIndex

    ; (.)は文字列の結合
    currentInput .= char

    ; 候補の再構築
    suggestions := makeSuggestions(currentInput)
    ; 
    if !suggestions.Length
        selectedIndex := 0
    else if selectedIndex > suggestions.Length
        selectedIndex := 1

    ; Tooltip 更新
    if currentInput {
        if suggestions.Length
            showTooltip(suggestions, selectedIndex)
        else
            showTooltip(["一致なし"], 0)
    }
}


;---
; あらかじめ登録したキーが押されるたびに呼ばれる
; vk: 仮想キーコード
;---
OnVKey(ih, vk, sc) {
    global currentInput, suggestions, selectedIndex
    ; Tab
    if (vk = 9) {
        ; 候補を循環
        if suggestions.Length {
            selectedIndex := selectedIndex < suggestions.Length
                                             ? selectedIndex + 1
                                             : 1
            showTooltip(suggestions, selectedIndex)
        }
    }
    ; Backspace
    else if (vk = 8) {
        ; 末尾 1 文字を削除
        currentInput := SubStr(currentInput, 1, -1)
        suggestions := makeSuggestions(currentInput)
        ; 削除によって候補は減らないので selectedIndex はそのままで問題ない
        showTooltip(suggestions, selectedIndex)
    }
}

;---
; あらかじめ登録した InputHook 終了キーが押されたときに呼ばれる
;---
OnEnd(ih) {
    global suggestions, selectedIndex

    ; Tooltip 消去
    ToolTip()

    ; Enter
    if (ih.EndKey = "Enter") {
        ; 選択中の記号を挿入
        if suggestions.Length && selectedIndex
            SendInput suggestions[selectedIndex].sym
    }
}

;---
; 文字入力（input）に対応する候補集合（suggestions）の構築
;---
makeSuggestions(input) {
    suggestions := []
    if currentInput {
        for key, sym in symbolMap {
            ; 前方一致=一致部分が文字列の先頭
            if InStr(key, input) = 1
                suggestions.Push({key: key, sym: sym})
        }
    }
    return suggestions
}

;---
; 候補記号集合（cands）を、現在の選択位置（idx）とともに表示する
;   cands: [{key: "...", sym: "..."}, ...]
;   idx: 選択インデックス（1 始まり）
;---
showTooltip(cands, idx) {
    if cands.Length {
        str := ""
        for i, item in cands {
            text := item.key . "  :  " . item.sym
            prefix := (i = idx) ? "→ " : "   "
            str .= prefix . text . "`n"
        }
    }
    else
        str := "一致なし"

    ; キャレット位置取得して吹き出し
    ; …したかったが、ブラウザに入力するときうまくいかないので無し
    ; CaretGetPos &x, &y
    ToolTip str
}