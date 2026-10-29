# Манифест требований

Источник: `2026-10-29-brief.md`.

| ID | Из брифа (дословно) | Статус | Основание | Где |
|----|---------------------|--------|-----------|-----|
| R01 | «на MacBook ... держать её и на планшете через Apple Pencil что-либо проводить» | in-ticket | Native Mac app and mirrored Sidecar | spec.md → T01 |
| R02 | «пока она зажатая, Apple Pencil работает как подчёркивание» | in-ticket | Hold-to-draw, underlying clicks blocked only while held | spec.md → T01 |
| R03 | «не на две-три секунды, а пока зажато» | in-ticket | Never fade while held | spec.md → T01 |
| R04 | «когда отпускаю, то это медленно растворяется» | in-ticket | 1.4 second fade after release; input immediately restored | spec.md → T01 |
| R05 | «она не выделяет текст ... работает как такой маркер» | in-ticket | Overlay owns pointer events during hold | spec.md → T01 |
| R06 | «я отпускаю клавишу, и всё возвращается обратно» | in-ticket | Fail-open global input state | spec.md → T01 |
| R07 | «выбор цвета ... из палитры» | in-ticket | Native arbitrary color picker | spec.md → T01 |
| R08 | «непрозрачности ... любую» | in-ticket | Continuous opacity setting | spec.md → T01 |
| R09 | «толщину ... любую» | in-ticket | Continuous stroke width setting | spec.md → T01 |
| R10 | «горячую клавишу ... любую» | in-ticket | Recorder for key/chord or single modifier; OS-reserved keys excluded | spec.md → T01 |
| R11 | «на GitHub в открытый репозиторий, там же его проверять» | in-ticket | Public repo and one manually dispatched final CI | spec.md → T02 |
| R12 | «подписать его мной» | in-ticket | Developer ID signature using owner certificate | spec.md → T02 |
| R13 | «установить его ... на постоянной основе» | in-ticket | Applications install and login startup option | spec.md → T01 |
| R14 | «очень быстро, без кучи проверок, критиков» | in-ticket | No critic/independent review; essential build, smoke, signing only | spec.md → T02 |
| R15 | «Всё, больше ничего не нужно» | in-ticket | No accounts, networking, extra drawing tools, eraser, update service | spec.md → T01 |
