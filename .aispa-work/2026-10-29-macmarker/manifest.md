# Манифест требований

Источник: `2026-10-29-brief.md`.

| ID | Из брифа (дословно) | Статус | Основание | Где |
|----|---------------------|--------|-----------|-----|
| R01 | «на MacBook ... держать её и на планшете через Apple Pencil что-либо проводить» | done | Native Mac app and mirrored Sidecar | spec.md → T01 |
| R02 | «пока она зажатая, Apple Pencil работает как подчёркивание» | done | Hold-to-draw, underlying clicks blocked only while held | spec.md → T01 |
| R03 | «не на две-три секунды, а пока зажато» | done | Never fade while held | spec.md → T01 |
| R04 | «когда отпускаю, то это медленно растворяется» | done | 1.4 second fade after release; input immediately restored | spec.md → T01 |
| R05 | «она не выделяет текст ... работает как такой маркер» | done | Overlay owns pointer events during hold | spec.md → T01 |
| R06 | «я отпускаю клавишу, и всё возвращается обратно» | done | Fail-open global input state | spec.md → T01 |
| R07 | «выбор цвета ... из палитры» | done | Native arbitrary color picker | spec.md → T01 |
| R08 | «непрозрачности ... любую» | done | Continuous opacity setting | spec.md → T01 |
| R09 | «толщину ... любую» | done | Continuous stroke width setting | spec.md → T01 |
| R10 | «горячую клавишу ... любую» | done | Recorder for key/chord or single modifier; OS-reserved keys excluded | spec.md → T01 |
| R11 | «на GitHub в открытый репозиторий, там же его проверять» | done | Public repo and one manually dispatched final CI | spec.md → T02 → e5f4214 |
| R12 | «подписать его мной» | done | Developer ID signature using owner certificate | spec.md → T02 → e5f4214 |
| R13 | «установить его ... на постоянной основе» | done | Applications install and login startup option | spec.md → T01 |
| R14 | «очень быстро, без кучи проверок, критиков» | done | No critic/independent review; essential build, smoke, signing only | spec.md → T02 → e5f4214 |
| R15 | «Всё, больше ничего не нужно» | done | No accounts, networking, extra drawing tools, eraser, update service | spec.md → T01 |
| D01 | Toolchain changed externally during run: Xcode26.6 →27.1 with new license prompt; CLT manifest ABI is inconsistent | in-spec | No system/license changes. Use clean final hosted build artifact if local packaging cannot rebuild. | spec.md |
| D02 | First CI failed before compile because version parser read the swift-driver version | in-spec | Parser fixed; one corrected final CI is necessary for the repaired final set. | verify.yml |
