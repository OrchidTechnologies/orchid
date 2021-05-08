
def get_product_id_mapping(store: str = 'apple') -> dict:
    mapping = {}
    mapping['apple'] = {
        'net.orchid.pactier1': 39.99,
        'net.orchid.pactier2': 79.99,
        'net.orchid.pactier3': 199.99,
        'net.orchid.pactier4': 0.99,
        'net.orchid.pactier5': 9.99,
        'net.orchid.pactier6': 99.99,
        'net.orchid.pactier10': 4.99,
        'net.orchid.pactier11': 19.99
    }
     mapping['google'] = {
         'net.orchid.pactier1': 4.99,
         'net.orchid.pactier2': 9.99,
         'net.orchid.pactier3': 19.99,
     }
    return mapping.get(store, {})
