<?php

namespace App\Support;

/**
 * Numéros de téléphone camerounais.
 * On les enregistre toujours au format national à 9 chiffres (ex. 690000000),
 * quelle que soit la saisie : "6 90 00 00 00", "+237 690 00 00 00", "00237690000000"...
 */
class Phone
{
    /** Renvoie le numéro à 9 chiffres, ou null s'il est invalide. */
    public static function normalize(?string $raw): ?string
    {
        $d = preg_replace('/\D+/', '', (string) $raw);
        if ($d === '') return null;
        if (str_starts_with($d, '00')) $d = substr($d, 2);
        if (str_starts_with($d, '237') && strlen($d) === 12) $d = substr($d, 3);

        // 6xxxxxxxx (mobiles) ou 2xxxxxxxx (fixes)
        return preg_match('/^[26]\d{8}$/', $d) === 1 ? $d : null;
    }

    /** Format international pour un lien d'appel (tel:). */
    public static function dial(?string $national): ?string
    {
        return $national ? '+237' . $national : null;
    }

    /** Affichage lisible : 6 90 00 00 00 */
    public static function pretty(?string $national): ?string
    {
        if (! $national || strlen($national) !== 9) return $national;

        return substr($national, 0, 1) . ' ' . implode(' ', str_split(substr($national, 1), 2));
    }
}
