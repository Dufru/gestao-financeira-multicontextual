import 'package:flutter/material.dart';
import '../models/categoria.dart';
import '../models/transacao.dart';
import '../utils/formatters.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transacao,
    required this.categorias,
    required this.onTap,
    required this.onDelete,
  });

  final Transacao transacao;
  final List<Categoria> categorias;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final receita = transacao.tipo == 'receita';
    final categoria = categorias.where((c) => c.id == transacao.categoriaId);
    final nomeCategoria = categoria.isEmpty ? 'Sem categoria' : categoria.first.nome;
    final cor = receita ? const Color(0xFF14805E) : const Color(0xFFCC5E4B);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  receita ? Icons.south_west_rounded : Icons.north_east_rounded,
                  color: cor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transacao.descricao,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$nomeCategoria · ${formatarData(transacao.data)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${receita ? '+' : '−'} ${formatarMoeda(transacao.valorCentavos)}',
                style: TextStyle(
                  color: cor,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opções do lançamento',
                onSelected: (opcao) {
                  if (opcao == 'editar') onTap();
                  if (opcao == 'excluir') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'editar', child: Text('Editar')),
                  PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                ],
                icon: const Icon(Icons.more_vert_rounded, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
