window.STATE =
{
  "version": 2,
  "slug": "macmarker",
  "dir": "2026-10-29-macmarker--wip",
  "title": "MacMarker — маркер по удержанию клавиши",
  "mode": "auto",
  "depth": "strict",
  "questions": null,
  "tier": "T1",
  "briefFile": "2026-10-29-brief.md",
  "memoryFile": "AGENTS.md",
  "memoryOwner": "user",
  "skillDir": "/Users/AlexFisenkov/.agents/skills/aispa",
  "skillVersion": "1.0.2",
  "baseCommit": null,
  "startedAt": "2026-10-29T23:10:19+08:00",
  "updatedAt": "2026-10-29T23:12:23+08:00",
  "finishedAt": null,
  "stages": [
    {
      "id": "preflight",
      "status": "done",
      "startedAt": "2026-10-29T23:10:19+08:00",
      "finishedAt": "2026-10-29T23:11:10+08:00"
    },
    {
      "id": "manifest",
      "status": "done",
      "startedAt": "2026-10-29T23:11:10+08:00",
      "finishedAt": "2026-10-29T23:11:55+08:00"
    },
    {
      "id": "briefing",
      "status": "skipped",
      "startedAt": "2026-10-29T23:11:10+08:00",
      "finishedAt": "2026-10-29T23:11:10+08:00",
      "note": "auto/fast: бриф однозначен, решения записаны; без критиков по прямому указанию"
    },
    {
      "id": "spec",
      "status": "done",
      "startedAt": "2026-10-29T23:11:55+08:00",
      "finishedAt": "2026-10-29T23:12:23+08:00"
    },
    {
      "id": "plan",
      "status": "active",
      "startedAt": "2026-10-29T23:12:23+08:00"
    },
    {
      "id": "build",
      "status": "pending"
    },
    {
      "id": "review",
      "status": "pending"
    },
    {
      "id": "final",
      "status": "pending"
    }
  ],
  "requirements": {
    "total": 15,
    "done": 0,
    "inTicket": 15,
    "inSpec": 0,
    "placeholder": 0,
    "deferred": 0,
    "dropped": 0
  },
  "tickets": [
    {
      "id": "01",
      "title": "Удерживаемый маркер и настройки",
      "requirements": [
        "R01",
        "R02",
        "R03",
        "R04",
        "R05",
        "R06",
        "R07",
        "R08",
        "R09",
        "R10",
        "R13",
        "R15"
      ],
      "blockedBy": [],
      "wave": 1,
      "zone": [
        "Package.swift",
        "Sources/"
      ],
      "review": "нет — прямое указание владельца",
      "model": "сильная",
      "status": "pending",
      "retries": 0,
      "repairs": 0
    },
    {
      "id": "02",
      "title": "Публичный воспроизводимый выпуск",
      "requirements": [
        "R11",
        "R12",
        "R14"
      ],
      "blockedBy": [],
      "wave": 1,
      "zone": [
        "script/",
        "Resources/",
        ".github/",
        ".codex/",
        "README.md",
        "LICENSE"
      ],
      "review": "нет — прямое указание владельца",
      "model": "обычная",
      "status": "pending",
      "retries": 0,
      "repairs": 0
    }
  ],
  "tests": null,
  "debt": {
    "placeholders": [],
    "assumptions": [
      "Имя MacMarker; right Option по умолчанию; fade1.4сек; маркер перехватывает также мышь на время удержания."
    ],
    "emptyEnv": []
  },
  "additions": [],
  "coverage": null,
  "concerns": [],
  "blind": null,
  "beats": [
    "2026-10-29T23:10:19+08:00",
    "2026-10-29T23:11:10+08:00",
    "2026-10-29T23:11:55+08:00",
    "2026-10-29T23:12:23+08:00"
  ],
  "rev": 11,
  "waiting": null,
  "waits": [],
  "log": [
    {
      "t": "2026-10-29T23:10:19+08:00",
      "k": "init"
    },
    {
      "t": "2026-10-29T23:11:10+08:00",
      "k": "stage",
      "id": "manifest",
      "act": "start"
    },
    {
      "t": "2026-10-29T23:11:10+08:00",
      "k": "tier",
      "v": "T1"
    },
    {
      "t": "2026-10-29T23:11:10+08:00",
      "k": "stage",
      "id": "briefing",
      "act": "skip",
      "note": "auto/fast: бриф однозначен, решения записаны; без критиков по прямому указанию"
    },
    {
      "t": "2026-10-29T23:11:55+08:00",
      "k": "gate",
      "g": "G1",
      "ok": true,
      "open": 0,
      "total": 15
    },
    {
      "t": "2026-10-29T23:11:55+08:00",
      "k": "stage",
      "id": "spec",
      "act": "start"
    },
    {
      "t": "2026-10-29T23:11:55+08:00",
      "k": "add",
      "key": "report",
      "n": 1
    },
    {
      "t": "2026-10-29T23:11:55+08:00",
      "k": "add",
      "key": "debt.assumptions",
      "n": 1
    },
    {
      "t": "2026-10-29T23:12:23+08:00",
      "k": "stage",
      "id": "plan",
      "act": "start"
    },
    {
      "t": "2026-10-29T23:12:23+08:00",
      "k": "tickets",
      "n": 2
    },
    {
      "t": "2026-10-29T23:12:23+08:00",
      "k": "gate",
      "g": "G3",
      "ok": true,
      "problems": 0
    }
  ],
  "reqList": [
    {
      "id": "R01",
      "text": "«на MacBook ... держать её и на планшете через Apple Pencil что-либо проводить»",
      "status": "in-ticket"
    },
    {
      "id": "R02",
      "text": "«пока она зажатая, Apple Pencil работает как подчёркивание»",
      "status": "in-ticket"
    },
    {
      "id": "R03",
      "text": "«не на две-три секунды, а пока зажато»",
      "status": "in-ticket"
    },
    {
      "id": "R04",
      "text": "«когда отпускаю, то это медленно растворяется»",
      "status": "in-ticket"
    },
    {
      "id": "R05",
      "text": "«она не выделяет текст ... работает как такой маркер»",
      "status": "in-ticket"
    },
    {
      "id": "R06",
      "text": "«я отпускаю клавишу, и всё возвращается обратно»",
      "status": "in-ticket"
    },
    {
      "id": "R07",
      "text": "«выбор цвета ... из палитры»",
      "status": "in-ticket"
    },
    {
      "id": "R08",
      "text": "«непрозрачности ... любую»",
      "status": "in-ticket"
    },
    {
      "id": "R09",
      "text": "«толщину ... любую»",
      "status": "in-ticket"
    },
    {
      "id": "R10",
      "text": "«горячую клавишу ... любую»",
      "status": "in-ticket"
    },
    {
      "id": "R11",
      "text": "«на GitHub в открытый репозиторий, там же его проверять»",
      "status": "in-ticket"
    },
    {
      "id": "R12",
      "text": "«подписать его мной»",
      "status": "in-ticket"
    },
    {
      "id": "R13",
      "text": "«установить его ... на постоянной основе»",
      "status": "in-ticket"
    },
    {
      "id": "R14",
      "text": "«очень быстро, без кучи проверок, критиков»",
      "status": "in-ticket"
    },
    {
      "id": "R15",
      "text": "«Всё, больше ничего не нужно»",
      "status": "in-ticket"
    }
  ],
  "gates": {
    "G1": {
      "ok": true,
      "at": "2026-10-29T23:11:55+08:00",
      "open": 0,
      "total": 15
    },
    "G3": {
      "ok": true,
      "at": "2026-10-29T23:12:23+08:00",
      "problems": 0
    }
  },
  "result": null,
  "report": [
    "По прямому указанию владельца: без критиков, независимого G2 и слепой приёмки; только необходимые build/runtime/signature/CI проверки."
  ]
}
