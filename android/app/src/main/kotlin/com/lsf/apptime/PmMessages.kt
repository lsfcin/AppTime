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
            "You've hit your daily screen limit. Excessive use may impair prefrontal control. Consider stepping away, your brain needs recovery."
        else
            "Você atingiu seu limite diário de tela. Uso excessivo pode prejudicar o controle pré-frontal. Considere se afastar, seu cérebro também precisa de tempo para se recuperar."

    /** Per-app 24h limit doubled. [appName] = last segment of package. */
    fun appLimitExceeded(lang: String, appName: String): String =
        if (lang == "en")
            "$appName: Daily limit exceeded. Each extra minute deepens the habit loop. Your attention is a finite resource; value it."
        else
            "$appName: Limite diário excedido. Cada minuto extra reforça o ciclo do hábito. Sua atenção é um recurso esgotável; valorize-a."

    /** Current session doubled the max-session limit. */
    fun sessionExceeded(lang: String): String =
        if (lang == "en")
            "This session has gone too long. After interruption, focus takes 23 min back. Take a real break, move your body."
        else
            "Essa sessão está longa demais. Interrompido agora, o foco leva 23 min pra voltar. Faça uma pausa, mexa o corpo."

    /** Phone used after sleep-cutoff hour. */
    fun sleepingHours(lang: String): String =
        if (lang == "en")
            "Screens this late delay your melatonin. Blue light shifts sleep hormones by 30 min. Put it down, protect your deep sleep."
        else
            "Uso de telas a esta hora atrasam sua melatonina. Luz azul adia os hormônios do sono em 30 min. Experimenta guardar o celular, cuide do seu sono profundo."

    /** Social app opened before wakeup-hour threshold. */
    fun wakeupSocial(lang: String): String =
        if (lang == "en")
            "Social media at wakeup may spike cortisol. Your brain deserves a calm, intentional start. Own your morning routine, avoid noise, triggering messages notifications and feeds."
        else
            "Redes sociais ao acordar podem elevar o cortisol. Seu cérebro merece um início calmo e intencional. Cuide da sua manhã; evite ruídos e perturbações de mensagens, notificações e feeds."

    /** Triggered 3 s after an unlock when unlock count exceeds limit. */
    fun unlockExceeded(lang: String): String =
        if (lang == "en")
            "Too many unlocks today. Each one conditions an impulsive checking habit. Before proceeding, take a breath and perform a sanity check about why did you unlock it."
        else
            "Desbloqueios demais hoje. Cada um reforça o hábito impulsivo de verificar. Antes de prosseguir, respira fundo e aproveita para avaliar o motivo de ter destravado o smartphone."
}
