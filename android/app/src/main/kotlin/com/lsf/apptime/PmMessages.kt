package com.lsf.apptime

/**
 * F.PM messages — 2-3 short phrases, ~8 words each, no trailing dot, lowercase first letter.
 * Pairs the behavioral trigger with a sharp research-backed WHY.
 * No forced line breaks — text wraps naturally to overlay width.
 */
object PmMessages {

    /** 24h total phone time doubled the limit. */
    fun phoneTimeExceeded(lang: String): String =
        if (lang == "en")
            "you've hit your daily screen limit — excessive use may impair prefrontal control — step away, your brain needs recovery"
        else
            "você atingiu seu limite diário de tela — uso excessivo pode prejudicar o controle pré-frontal — afaste-se, seu cérebro precisa recuperar"

    /** Per-app 24h limit doubled. [appName] = last segment of package. */
    fun appLimitExceeded(lang: String, appName: String): String =
        if (lang == "en")
            "$appName: daily limit exceeded — each extra minute deepens the habit loop — your attention is worth more than this"
        else
            "$appName: limite diário excedido — cada minuto extra reforça o ciclo do hábito — sua atenção vale mais do que isso"

    /** Current session doubled the max-session limit. */
    fun sessionExceeded(lang: String): String =
        if (lang == "en")
            "this session has gone too long — after interruption, focus takes 23 min back — take a real break, move your body"
        else
            "essa sessão está longa demais — interrompido agora, foco leva 23 min pra voltar — faça uma pausa, mexa o corpo"

    /** Phone used after sleep-cutoff hour. */
    fun sleepingHours(lang: String): String =
        if (lang == "en")
            "screens this late delay your melatonin — blue light shifts sleep hormones by 30 min — put it down, protect your deep sleep"
        else
            "telas agora atrasam sua melatonina — luz azul adia os hormônios do sono em 30 min — guarde o celular, proteja seu sono profundo"

    /** Social app opened before wakeup-hour threshold. */
    fun wakeupSocial(lang: String): String =
        if (lang == "en")
            "social media at wakeup may spike cortisol — your brain deserves a calm, intentional start — own your morning before the feed does"
        else
            "redes sociais ao acordar podem elevar o cortisol — seu cérebro merece um início calmo e intencional — cuide da sua manhã antes do feed"

    /** Triggered 3 s after an unlock when unlock count exceeds limit. */
    fun unlockExceeded(lang: String): String =
        if (lang == "en")
            "too many unlocks today — each one conditions an impulsive checking habit — ask yourself: what are you really looking for?"
        else
            "desbloqueios demais hoje — cada um reforça o hábito impulsivo de verificar — pergunte: o que você realmente busca?"
}
