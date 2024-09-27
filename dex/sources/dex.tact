import "@stdlib/deploy";

message Withdraw {
    value: Int as coins;
}

message Swap {
    amount: Int as coins;
    a_b: Int;
}

contract Dex with Deployable {

    override const storageReserve: Int = ton("0.1");
    solved: Bool;
    lock: Bool;
    tokena_amount: Int as coins;
    tokenb_amount: Int as coins;
    user_balances: map<Int, Int>;
    user_created: Bool;

    init(ctf: Int) {
        self.solved = false;
        self.lock = true;
        self.user_created = false;
        self.tokena_amount = 10;
        self.tokenb_amount = 10;
    }

    receive("CreateUser"){
        require(!self.user_created, "User created");        
        self.user_balances.set(1, 10);
        self.user_balances.set(2, 0);
        self.user_created = true;
    }

    receive(msg: Swap){
        let ctx: Context = context();
        require(ctx.value>=ton("0.14"),"insufficient pay for gas");
        require(self.user_created, "Not created");   
        let x: Int  = self.tokena_amount;
        let y: Int  = self.tokenb_amount;
        let user_a: Int = self.user_balances.get(1)!!;
        let user_b: Int = self.user_balances.get(2)!!;
        if(msg.a_b == 1){
            require(user_a >= msg.amount, "Insufficient balance");
            let out_amount: Int = y - (x*y)/(x + msg.amount);
            self.user_balances.set(1, user_a - msg.amount);
            self.user_balances.set(2, user_b + out_amount);
            self.tokena_amount = x + msg.amount;
            self.tokenb_amount = y - out_amount;
        }else {
            require(user_b >= msg.amount, "Insufficient balance");
            let out_amount: Int = x - (x*y)/(y + msg.amount);
            self.user_balances.set(1, user_a + out_amount);
            self.user_balances.set(2, user_b - msg.amount);
            self.tokena_amount = x - out_amount;  
            self.tokenb_amount = y + msg.amount;     
        }
        if (self.user_balances.get(1)!! + self.user_balances.get(2)!! == 29){
            self.lock = false;
        }
    }

    receive(msg: Withdraw) {
        require(!self.lock, "locking");
        // Get the current context
        let ctx: Context = context();
        // Require required balance
        require(myBalance() > ton("1.0") + self.storageReserve + msg.value, "Insufficient balance");
        // Withdraw
        send(SendParameters{
            value: msg.value, 
            mode: SendRemainingValue,
            to: ctx.sender, 
            body: "Withdraw сompleted".asComment()
        });
    }    

    receive("Solve"){
        require(!self.lock, "Locking");        
        if (myBalance()<ton("0.5")){
            self.solved = true;
        }
    }

    get fun is_solved(): Bool {
        return self.solved == true;
    }    


}
