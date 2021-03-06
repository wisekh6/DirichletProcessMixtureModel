posteriorbeta = function(c, beta, D, S, W) {
  
  ## Calculate the number of Active clusters
  
  
  g <- table(factor(c, levels = 1:K))
  active <- which(g!=0)
  Kplus <- length(active)
  
  
  ## Some temporary sums 
  sum.det = 0 
  sum.trace = 0
  
  
  for ( z in 1: Kplus) {
    sum.det <- sum.det + log(abs(det(S[active[z],1:D, 1:D])))
    sum.trace <-  sum.trace + matrix.trace( S[active[z],1:D, 1:D] %*% W )
    
  }
  sum.gamma = 0
  sum.digamma =0 
  
  
  
  
  f = function(x, D = D, Kp = Kplus, S1 = sum.det, S2 = sum.trace, W = W){
     0.5* x* Kp* log(abs(det(W))) + 0.5*((x - D -1)* S1) + 0.5 * (D*Kp*x * log (x/2)) - 0.5 *x *S2 - 1.5 *log(abs(x -D +1)) -  0.5 * (D/(x-D+1))
     - sum(sapply( c(1:D), function (v) Kp* lgamma(0.5*(x + v-D))))
    
  }
  
  fprima = function(x, D = D, Kp = Kplus, S1 = sum.det, S2 = sum.trace, W = W){
     0.5 * Kp *log(abs(det(W)))  +(0.5* S1) + 0.5 * D*Kp*(1 + log(x/2)) - 0.5 *S2 - 1.5 *((x -D +1)^-1) +  0.5 * (D/(x-D+1)^2) 
     - 0.5 * sum(sapply( c(1:D), function (v) Kp* digamma(0.5*(x + v-D))))
  }
  
  ars(1, f, fprima, x = beta , m =1, lb = TRUE, xlb =2, ub = TRUE ,  D = D, Kp = Kplus, S1 = sum.det, S2 = sum.trace, W = W) 
 
  
}
  