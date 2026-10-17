import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PrivacyPolicySheet extends StatelessWidget {
  const PrivacyPolicySheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkDivider : AppColors.divider,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: const [
              Icon(Icons.security_rounded, color: AppColors.primary, size: 24),
              SizedBox(width: 10),
              Text(
                'Gizlilik & KVKK Aydınlatma',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                'ÇiftApp olarak kişisel verilerinizin ve ilişkinize ait özel anıların güvenliğini en üst düzeyde tutuyoruz.\n\n'
                '1. Veri Sorumlusu ve Kapsam:\n'
                '6698 sayılı KVKK ve GDPR kapsamında, mesajlarınız, yüklediğiniz anı fotoğrafları ve planlarınız yalnızca eşleşmiş olduğunuz partneriniz ile sizin aranızda paylaşılır.\n\n'
                '2. Şifreleme ve Güvenlik:\n'
                'Tüm veriler aktarım sırasında ve sunucularımızda endüstri standardı TLS ve şifreleme yöntemleriyle saklanmaktadır.\n\n'
                '3. Veri Silme ve Unutulma Hakkı:\n'
                'Uygulama ayarlarından "Hesabı ve Verileri Sil" seçeneğini kullanarak dilediğiniz zaman tüm sohbet, görsel ve hesap kayıtlarınızı kalıcı olarak silebilirsiniz.\n\n'
                '4. Reklam ve Üçüncü Taraflar:\n'
                'Verileriniz asla reklam verenlere satılmaz veya hedefli reklam amacıyla üçüncü taraflarla paylaşılmaz.',
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anladım'),
          ),
        ],
      ),
    );
  }
}
