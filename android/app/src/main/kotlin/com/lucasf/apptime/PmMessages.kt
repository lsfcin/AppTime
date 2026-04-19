package com.lucasf.apptime

/**
 * F.PM messages — 2-3 lines, ~8 words each, no trailing dot, lowercase first letter.
 * Pairs the behavioral trigger with a sharp research-backed WHY.
 */
object PmMessages {

    /** 24h total phone time doubled the limit. */
    fun phoneTimeExceeded(lang: String): String =
        if (lang == "en")
            "you've hit your daily screen limit\nexcessive use may impair prefrontal control\nstep away — your brain needs recovery"
        else
            "você atingiu seu limite diário de tela\nuso excessivo pode prejudicar o controle pré-frontal\nafaste-se — seu cérebro precisa recuperar"

    /** Per-app 24h limit doubled. [appName] = last segment of package. */
    fun appLimitExceeded(lang: String, appName: String): String =
        if (lang == "en")
            "$appName: daily limit exceeded\neach extra minute deepens the habit loop\nyour attention is worth more than this"
        else
            "$appName: limite diário excedido\ncada minuto extra reforça o ciclo do hábito\nsua atenção vale mais do que isso"

    /** Current session doubled the max-session limit. */
    fun sessionExceeded(lang: String): String =
        if (lang == "en")
            "this session has gone too long\nafter interruption, focus takes 23 min back\ntake a real break — move your body"
        else
            "essa sessão está longa demais\ninterrompido agora, foco leva 23 min pra voltar\nfaça uma pausa — mexa o corpo"

    /** Phone used after sleep-cutoff hour. */
    fun sleepingHours(lang: String): String =
        if (lang == "en")
            "screens this late delay your melatonin\nblue light shifts sleep hormones by 30 min\nput it down — protect your deep sleep"
        else
            "telas agora atrasam sua melatonina\nluz azul adia os hormônios do sono em 30 min\nguarde o celular — proteja seu sono profundo"

    /** Social app opened before wakeup-hour threshold. */
    fun wakeupSocial(lang: String): String =
        if (lang == "en")
            "social media at wakeup may spike cortisol\nyour brain deserves a calm, intentional start\nown your morning before the feed does"
        else
            "redes sociais ao acordar podem elevar o cortisol\nseu cérebro merece um início calmo e intencional\ncuide da sua manhã antes do feed"

    /** Triggered 3 s after an unlock when unlock count exceeds limit. */
    fun unlockExceeded(lang: String): String =
        if (lang == "en")
            "too many unlocks today\neach one conditions an impulsive checking habit\nask yourself: what are you really looking for?"
        else
            "desbloqueios demais hoje\ncada um reforça o hábito impulsivo de verificar\npergunte: o que você realmente busca?"
}
