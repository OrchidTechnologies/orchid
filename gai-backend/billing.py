import json

disconnect_threshold = -0.002

def invoice(amt):
   return json.dumps({'type': 'invoice', 'amount': amt})

class Billing:
    def __init__(self, prices):
       self.ledger = {}
       self.prices = prices
    
    def credit(self, id, type=None, amount=0):
       self.adjust(id, type, amount, 1)

    def debit(self, id, type=None, amount=0):
       self.adjust(id, type, amount, -1)

    def adjust(self, id, type, amount, sign):
       amount_ = self.prices[type] if type is not None else amount
       if id in self.ledger:
          self.ledger[id] = self.ledger[id] + sign * amount_
       else:
          self.ledger[id] = sign * amount_

    def min_balance(self):
        return 2 * (self.prices['invoice'] + self.prices['payment'])
    
    def balance(self, id):
        if id in self.ledger:
           return self.ledger[id]
        else:
            return 0