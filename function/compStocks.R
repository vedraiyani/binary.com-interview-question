compStocks <- function(mbase, family = 'gaussian', xy.matrix = c('h1', 'h2'), 
                       maxit = 100000, alpha = 0:10, setform = c('l1', 'l2', 'l3', 'l4'), 
                       yv = c('baseline', 'open1', 'open2', 'high1', 'high2', 'low1', 'low2', 'close1', 'close2', 'daily.mean1', 'daily.mean2', 'daily.mean3', 'mixed1', 'mixed2', 'mixed3'), 
                       yv.lm = FALSE, newx = NULL, fordate = NULL, preset.weight = TRUE, 
                       pred.type = c('link', 'response', 'coefficients', 'nonzero', 'class'), 
                       tmeasure = 'mse', nfolds = 10, foldid = NULL, weight.dist = 'none', 
                       s = c('lambda.min', 'lambda.1se'), 
                       weight.date = FALSE, weight.volume = FALSE, wt.control = FALSE, 
                       parallel = TRUE, .log = FALSE, .print = FALSE, .save = FALSE, 
                       pth = './data') {
  ## ========================= Load Packages ===================================
  suppressAll(library('fdrtool'))
  suppressAll(source('./function/phalfnorm.R'))
  suppressAll(source('./function/glmPrice.R'))
  
  ## ========================= Set Arguments ===================================
  #'@ mbase <- LADDT
  families <- c('gaussian', 'binomial', 'poisson', 'multinomial', 'cox', 'mgaussian', 'all')
  #'@ xy.matrix <- c('h1', 'h2')
  #'@ alpha <- 0:10
  #'@ 
  #'@ yv <- c('baseline', 'daily.mean1', 'daily.mean2', 'daily.mean3', 'mixed1', 'mixed2', 'mixed3')
  #'@ setform <- c('l1', 'l2', 'l3', 'l4')
  #'@ pred.type <- c('link', 'response', 'coefficients', 'nonzero', 'class')
  #'@ 
  #'@ nfolds = 10
  #'@ foldid = NULL
  #'@ s = c('lambda.min', 'lambda.1se')
  #'@ 
  #'@ weight.date = FALSE     #weight.date is ...
  #'@ weight.volume = FALSE   #weight.volume is ...
  #'@ parallel = FALSE
  #'@ .log = FALSE
  
  ## ======================= Data Validation ===================================
  if(family %in% families) {
    family <- family
  } else {
    stop("family must be within c('gaussian', 'binomial', 'poisson', 'multinomial', 'cox', 'mgaussian', 'all').")
  }
  alpha <- ifelse(length(alpha) > 1, paste(range(alpha), collapse = ':'), alpha)
  nfolds <- ifelse(length(nfolds) > 1, paste(range(nfolds), collapse = ':'), nfolds)
  
  ## Due to simulate all families models will costing a lot of time, here I only use Gassian as time being.
  ##   Test Poisson, Logistics and Multinomial models but a baseline need to multiply to the coefficients for mse comparison etc. 
  ##   Filter few stages with adjustment of the independent and dependent variables to shrink to the 224 models now.
  if(preset.weight == TRUE & family != 'gaussian') {
    stop('preset.weight only applicable to family = "gaussian" as time being.')
  }
  
  if(is.null(foldid)) {
    foldid <- 'NULL'
  } else {
    foldid <- ifelse(length(foldid) > 1, paste(range(foldid), collapse = ':'), foldid)
  }
  
  if(all(yv.lm %in% c(TRUE, FALSE))) {
    yv.lm <- yv.lm
  } else {
    yv.lm <- c(TRUE, FALSE)
  }
  
  if(!is.null(newx)) x <- newx
  
  if(.save == TRUE) {
    txt = 'saved'
  } else {
    txt = 'calculated'
  }
  
  ## temporary function for comparison among 224 models.
  #'@ if(is.null(predate)) {
  #'@    folder <- list.files('./data', pattern = '[0-9]{8}')
  #'@ } else if() {
  #'@    read_rds(path = paste0('./data/', fld, '/wt.fitgaum', 1:224, '.rds'))
  #'@ } else {
  #'@   
  #'@ }
  
  ## ======================== Regression Models ================================
  if((family == 'gaussian')|(family == 'all')) {
    ## -------------------------- gaussian --------------------------------
    ## 3 models : tmeasure = 'deviance' or tmeasure = 'mse' or tmeasure = 'mae'.
    if(tmeasure %in% c('deviance', 'mse', 'mae')) {
      tmeasure <- tmeasure
    } else {
      tmeasure <- c('deviance', 'mse', 'mae')
    }
    
    family <- 'gaussian'
    
    if(pred.type %in% c('link', 'response', 'nonzero', 'class')) {
      pred.type <- pred.type
    } else {
      pred.type <- c('link', 'response', 'nonzero', 'class')
    }
      
    if(wt.control %in% c(TRUE, FALSE)) {
      wt.control <- wt.control
    } else {
      wt.control = c(TRUE, FALSE)
    }
    
    ## preset.weight is a temporarily setting for 224 models.
    if(preset.weight == TRUE) {
      
      gaum <- sapply(xy.matrix, function(x) {
        sapply(yv, function(y) {
          sapply(yv.lm, function(yy) {
            sapply(tmeasure, function(z) {
              sapply(pred.type, function(xx) {
                sapply(s, function(xy) {
                  sapply(setform, function(xz) {
                    sapply(wt.control, function(yx) {
                      paste0('glmPrice(mbase, family = \'', family, '\', xy.matrix = \'', x, 
                             '\', setform = \'', xz, '\', yv = \'', y, '\', yv.lm = ', yy, 
                             ', tmeasure = \'', z, '\', maxit = ', maxit, 
                             ', newx = newx, pred.type = \'', xx, '\', fordate = fordate', 
                             ', alpha = ', alpha, ', nfolds = ', nfolds, 
                             ', foldid = ', foldid, ', s = \'', xy, '\', preset.weight = preset.weight, ', 
                             'weight.date = weight.date, weight.volume = weight.volume, wt.control = ', yx, 
                             ', parallel = ', parallel, ', .log = ', .log, ')')
                    })
                  })
                })
              })
            })
          })
        })
      }) %>% as.character
    
      weight.volume <- split(weight.volume, as.numeric(rownames(weight.volume)))
      #'@ weight.date <- exp(-log(as.numeric(difftime(dt, smp$Date))^2))
      gaum <- str_replace_all(gaum, 'weight.volume = weight.volume', paste('weight.volume =', weight.volume))
      
    } else if (preset.weight == FALSE) {
      
      gaum <- sapply(xy.matrix, function(x) {
        sapply(yv, function(y) {
          sapply(yv.lm, function(yy) {
            sapply(tmeasure, function(z) {
              sapply(pred.type, function(xx) {
                sapply(s, function(xy) {
                  sapply(setform, function(xz) {
                    sapply(wt.control, function(yx) {
                      paste0('glmPrice(mbase, family = \'', family, '\', xy.matrix = \'', x, 
                             '\', setform = \'', xz, '\', yv = \'', y, '\', yv.lm = ', yy, 
                             ', tmeasure = \'', z, '\', maxit = ', maxit, 
                             ', newx = newx, pred.type = \'', xx, '\', fordate = fordate', 
                             ', alpha = ', alpha, ', nfolds = ', nfolds, 
                             ', foldid = ', foldid, ', s = \'', xy, 
                             '\', weight.date = ', weight.date, ', weight.volume = ', 
                             weight.volume, ', wt.control = ', yx, 
                             ', parallel = ', parallel, ', .log = ', .log, ')')
                    })
                  })
                })
              })
            })
          })
        })
      }) %>% as.character
      
    } else {
      stop('Please make sure preset.weight = TRUE & length(gaum) == 224 for models comparison.')
    }
    
    #'@ if(weight.date != FALSE | weight.volume!= FALSE) nam <- 'wtfitgaum' else nam <- 'fitgaum'
    if(weight.dist == 'pnorm') {
      nam <- 'wt.pnorm.fitgaum'
    } else if(weight.dist == 'phalfnorm') {
      nam <- 'wt.phalfnorm.fitgaum'
    } else if(weight.dist == 'none') {
      nam <- 'fitgaum'
    } else {
      stop('Kindly select weight.dist = "pnorm" or weight.dist = "phalfnorm" or weight.dist = "none".')
    }
    
    gm <- paste(paste0(
      nam, seq(gaum), " <- ", gaum, 
      "; if(.save == TRUE) saveRDS(", nam, seq(gaum), ", file = '", pth, "/", nam, seq(gaum), ".rds')", 
      "; if(.print == TRUE) cat('gaussian model ", pth, ' : ', as.character(now()), ' : ', seq(gaum), "/", length(gaum), " ", txt, ".\n')"), 
      collapse = "; ")
    
    ## start algorithmic calculation.
    eval(parse(text = gm)); rm(gm)
    
    if(nam == 'fitgaum') {
      ## combine all fitgaum1 to fitgaum~ into a list named fitgaum
      ## fitgaum
      eval(parse(text = paste0('fitgaum <- list(', 
                               paste(paste0(nam, seq(gaum), ' = ', 'fitgaum', seq(gaum)), 
                                     collapse = ', '), ')')))
      
      ## rm all fitgaum1 to fitgaum~
      eval(parse(text = paste0('rm(', paste0(paste0('fitgaum', seq(gaum)), 
                                             collapse = ', '), ')')))
      
      tmp1 <- list(formula1 = gaum, fit = fitgaum)
      
    } else if(nam == 'wt.pnorm.fitgaum') {
      ## wt.pnorm.fitgaum
      eval(parse(text = paste0('wt.pnorm.fitgaum <- list(', 
                               paste(paste0(nam, seq(gaum), ' = ', 'wt.pnorm.fitgaum', seq(gaum)), 
                                     collapse = ', '), ')')))
      
      ## rm all wt.pnorm.fitgaum1 to wt.pnorm.fitgaum~
      eval(parse(text = paste0('rm(', paste0(paste0('wt.pnorm.fitgaum', seq(gaum)), 
                                             collapse = ', '), ')')))
      
      tmp1 <- list(formula1 = gaum, fit = wt.pnorm.fitgaum)
      
    } else if(nam == 'wt.phalfnorm.fitgaum') {
      ## wt.phalfnorm.fitgaum
      eval(parse(text = paste0('wt.phalfnorm.fitgaum <- list(', 
                               paste(paste0(nam, seq(gaum), ' = ', 'wt.phalfnorm.fitgaum', seq(gaum)), 
                                     collapse = ', '), ')')))
      
      ## rm all wt.phalfnorm.fitgaum1 to wt.phalfnorm.fitgaum~
      eval(parse(text = paste0('rm(', paste0(paste0('wt.phalfnorm.fitgaum', seq(gaum)), 
                                             collapse = ', '), ')')))
      
      tmp1 <- list(formula1 = gaum, fit = wt.phalfnorm.fitgaum)
      
    } else {
      stop('Kindly select weight.dist = "pnorm" or weight.dist = "phalfnorm" or weight.dist = "none".')
    }
    
    ## return if single family
    if(family == 'gaussian') return(tmp1)
    
    
  } else if((family == 'binomial')|(family == 'all')) {
    ## -------------------------- binomial --------------------------------
    ## 5 models : tmeasure = 'deviance' or tmeasure = 'mse' or 
    ##            tmeasure = 'mae' or tmeasure = 'class' or 
    ##            tmeasure = 'auc'.
    if(tmeasure %in% c('deviance', 'mse', 'mae', 'class', 'auc')) {
      tmeasure <- tmeasure
    } else {
      tmeasure <- c('deviance', 'mse', 'mae', 'class', 'auc')
    }
    
    family <- 'binomial'
    
    if(pred.type %in% c('link', 'response', 'nonzero', 'class')) {
      pred.type <- pred.type
    } else {
      pred.type <- c('link', 'response', 'nonzero', 'class')
    }
    wt.control = FALSE #wt.control not applicable in binomial nor multinomial.
    
    binm <- sapply(xy.matrix, function(x) {
      sapply(yv, function(y) {
        sapply(tmeasure, function(z) {
          sapply(pred.type, function(xx) {
            sapply(s, function(xy) {
              sapply(setform, function(xz) {
                sapply(wt.control, function(yx) {
                  paste0('glmPrice(mbase, family = \'', family, '\', xy.matrix = \'', x, 
                         '\', setform = \'', xz, '\', yv = \'', y, '\', tmeasure = \'', z, 
                         '\', maxit = ', maxit, ', newx = newx, pred.type = \'', xx, 
                         '\', alpha = ', alpha, ', nfolds = ', nfolds, 
                         ', foldid = ', foldid, ', s = \'', xy,  '\', fordate = fordate', 
                         ', weight.date = ', weight.date, ', weight.volume = ', 
                         weight.volume, ', wt.control = ', yx, 
                         ', parallel = ', parallel, ', .log = ', .log, ')')
                })
              })
            })
          })
        })
      })
    }) %>% as.character
    
    #'@ if(weight.date != FALSE | weight.volume!= FALSE) nam <- 'wtfitbinm' else nam <- 'fitbinm'
    if(weight.dist == 'pnorm') {
      nam <- 'wt.pnorm.fitbinm'
    } else if(weight.dist == 'phalfnorm'){
      nam <- 'wt.phalfnorm.fitbinm'
    } else if(weight.dist == 'none') {
      nam <- 'fitbinm'
    } else {
      stop('Kindly select weight.dist = "pnorm" or weight.dist = "phalfnorm" or weight.dist = "none".')
    }
    
    bm <- paste(paste0(
      nam, seq(binm), " <- ", binm, 
      "; if(.save == TRUE) saveRDS(", nam, seq(binm), ", file = '", pth, "/", nam, seq(binm), ".rds')", 
      "; if(.print == TRUE) cat('binomial model ",  pth, ' : ', as.character(now()), ' : ', seq(binm), "/", length(binm), " ", txt, ".\n')"), 
      collapse = "; ")
    
    ## start algorithmic calculation.
    eval(parse(text = bm)); rm(bm)
    
    if(nam == 'fitbinm') {
      ## combine all fitbinm1 to fitbinm~ into a list named fitbinm
      eval(parse(text = paste0('fitbinm <- list(', 
                               paste(paste0(nam, seq(binm), ' = ', 'fitbinm', seq(binm)), 
                                     collapse = ', '), ')')))
      
      ## rm all fitbinm1 to fitbinm~
      eval(parse(text = paste0('rm(', paste0(paste0('fitbinm', seq(binm)), 
                                             collapse = ', '), ')')))
      
      tmp2 <- list(formula1 = binm, fit = fitbinm)
      
    } else {
      eval(parse(text = paste0('wtfitbinm <- list(', 
                               paste(paste0(nam, seq(binm), ' = ', 'wtfitbinm', seq(binm)), 
                                     collapse = ', '), ')')))
      
      ## rm all wtfitbinm1 to wtfitbinm~
      eval(parse(text = paste0('rm(', paste0(paste0('wtfitbinm', seq(binm)), 
                                             collapse = ', '), ')')))
      
      tmp2 <- list(formula1 = binm, fit = wtfitbinm)
    }
    
    ## return if single family
    if(family == 'binomial') return(tmp2)
    
    
  } else if((family == 'poisson')|(family == 'all')) {
    ## -------------------------- poisson ---------------------------------
    ## 3 models : tmeasure = 'deviance' or tmeasure = 'mse' or tmeasure = 'mae'.
    if(tmeasure %in% c('deviance', 'mse', 'mae')) {
      tmeasure <- tmeasure
    } else {
      tmeasure <- c('deviance', 'mse', 'mae')
    }
    
    family <- 'poisson'
    
    if(pred.type %in% c('link', 'response', 'nonzero')) {
      pred.type <- pred.type
    } else {
      pred.type <- c('link', 'response', 'nonzero')
    }
    
    if(wt.control %in% c(TRUE, FALSE)) {
      wt.control <- wt.control
    } else {
      wt.control = c(TRUE, FALSE)
    }
    
    poim <- sapply(xy.matrix, function(x) {
      sapply(yv, function(y) {
        sapply(yv.lm, function(yy) {
          sapply(tmeasure, function(z) {
            sapply(pred.type, function(xx) {
              sapply(s, function(xy) {
                sapply(setform, function(xz) {
                  sapply(wt.control, function(yx) {
                    paste0('glmPrice(mbase, family = \'', family, '\', xy.matrix = \'', x, 
                           '\', setform = \'', xz, '\', yv = \'', y, '\', yv.lm = ', yy, 
                           ', tmeasure = \'', z, '\', maxit = ', maxit, 
                           ', newx = newx, pred.type = \'', xx, '\', fordate = fordate', 
                           ', alpha = ', alpha, ', nfolds = ', nfolds, 
                           ', foldid = ', foldid, ', s = \'', xy, 
                           '\', weight.date = ', weight.date, ', weight.volume = ', 
                           weight.volume, ', wt.control = ', yx, 
                           ', parallel = ', parallel, ', .log = .log)')
                  })
                })
              })
            })
          })
        })
      })
    }) %>% as.character
    
    #'@ if(weight.date != FALSE | weight.volume!= FALSE) nam <- 'wtfitpoim' else nam <- 'fitpoim'
    if(weight.dist == 'pnorm') {
      nam <- 'wt.pnorm.fitpoim'
    } else if(weight.dist == 'phalfpoim'){
      nam <- 'wt.phalfnorm.fitpoim'
    } else if(weight.dist == 'none') {
      nam <- 'fitpoim'
    } else {
      stop('Kindly select weight.dist = "pnorm" or weight.dist = "phalfnorm" or weight.dist = "none".')
    }
    
    pm <- paste(paste0(
      nam, seq(poim), " <- ", poim, 
      "; if(.save == TRUE) saveRDS(", nam, seq(poim), ", file = '", pth, "/", nam, seq(poim), ".rds')", 
      "; if(.print == TRUE) cat('poisson model ",  pth, ' : ', as.character(now()), ' : ', seq(poim), "/", length(poim), " ", txt, ".\n')"), 
      collapse = "; ")
    
    ## start algorithmic calculation.
    eval(parse(text = pm)); rm(pm)
    
    if(nam == 'fitpoim') {
      ## combine all fitpoim1 to fitpoim~ into a list named fitpoim
      eval(parse(text = paste0('fitpoim <- list(', 
                               paste(paste0(nam, seq(poim), ' = ', 'fitpoim', seq(poim)), 
                                     collapse = ', '), ')')))
      
      ## rm all fitpoim1 to fitpoim~
      eval(parse(text = paste0('rm(', paste0(paste0('fitpoim', seq(poim)), 
                                             collapse = ', '), ')')))
      
      tmp3 <- list(formula1 = poim, fit = fitpoim)
      
    } else {
      eval(parse(text = paste0('wtfitpoim <- list(', 
                               paste(paste0(nam, seq(poim), ' = ', 'wtfitpoim', seq(poim)), 
                                     collapse = ', '), ')')))
      
      ## rm all wtfitpoim1 to wtfitpoim~
      eval(parse(text = paste0('rm(', paste0(paste0('wtfitpoim', seq(poim)), 
                                             collapse = ', '), ')')))
      
      tmp3 <- list(formula1 = poim, fit = wtfitpoim)
    }
    
    ## return if single family
    if(family == 'poisson') return(tmp3)
    
    
  } else if((family == 'multinomial')|(family == 'all')) {
    ## ----------------------- multinomial --------------------------------
    ## 4 models : tmeasure = 'deviance' or tmeasure = 'mse' or 
    ##            tmeasure = 'mae' or tmeasure = 'class'.
    ## 2 models : tmultinomial = 'grouped' or tmultinomial = 'ungrouped'.
    
    
    
    wt.control = FALSE #wt.control not applicable in binomial nor multinomial.
    
    if(tmeasure %in% c('deviance', 'mse', 'mae', 'class')) {
      tmeasure <- tmeasure
    } else {
      tmeasure <- c('deviance', 'mse', 'mae', 'class')
    }
    
    family <- 'multinomial'
    
    if(pred.type %in% c('link', 'response', 'nonzero', 'class')) {
      pred.type <- pred.type
    } else {
      pred.type <- c('link', 'response', 'nonzero', 'class')
    }
    
    tmultinomial <- c('grouped', 'ungrouped')
    wt.control = FALSE #wt.control not applicable in binomial nor multinomial.
    
    mnmm <- sapply(xy.matrix, function(x) {
      sapply(yv, function(y) {
        sapply(tmeasure, function(z) {
          sapply(pred.type, function(xx) {
            sapply(s, function(xy) {
              sapply(tmultinomial, function(tm) {
                sapply(setform, function(xz) {
                  sapply(wt.control, function(yx) {
                    paste0('glmPrice(mbase, family = \'', family, '\', xy.matrix = \'', x, 
                           '\', setform = \'', xz, '\', yv = \'', y, '\', tmeasure = \'', z, 
                           '\', tmultinomial = \'', tm, '\', maxit = ', maxit, 
                           ', newx = newx, pred.type = \'', xx, '\', fordate = fordate', 
                           ', alpha = ', alpha, ', nfolds = ', nfolds, 
                           ', foldid = ', foldid, ', s = \'', xy, 
                           '\', weight.date = ', weight.date, ', weight.volume = ', 
                           weight.volume, ', wt.control = ', yx, 
                           ', parallel = ', parallel, ', .log = .log)')
                  })
                })
              })
            })
          })
        })
      })
    }) %>% as.character
    
    #'@ if(weight.date != FALSE | weight.volume!= FALSE) nam <- 'wtfitmnmm' else nam <- 'fitmnmm'
    if(weight.dist == 'pnorm') {
      nam <- 'wt.pnorm.fitmnmm'
    } else if(weight.dist == 'phalfmnmm'){
      nam <- 'wt.phalfnorm.fitmnmm'
    } else if(weight.dist == 'none') {
      nam <- 'fitmnmm'
    } else {
      stop('Kindly select weight.dist = "pnorm" or weight.dist = "phalfnorm" or weight.dist = "none".')
    }
    
    mm <- paste(paste0(
      nam, seq(mnmm), " <- ", mnmm, 
      "; if(.save == TRUE) saveRDS(", nam, seq(mnmm), ", file = '", pth, "/", nam, seq(mnmm), ".rds')", 
      "; if(.print == TRUE) cat('multinomial model ",  pth, ' : ', as.character(now()), ' : ', seq(mnmm), "/", length(mnmm), " ", txt, ".\n')"), 
      collapse = "; ")
    
    ## start algorithmic calculation.
    eval(parse(text = mm)); rm(mm)
    
    if(nam == 'fitmnmm') {
      ## combine all fitmnmm1 to fitmnmm~ into a list named fitmnmm
      eval(parse(text = paste0('fitmnmm <- list(', 
                               paste(paste0(nam, seq(mnmm), ' = ', 'fitmnmm', seq(mnmm)), 
                                     collapse = ', '), ')')))
      
      ## rm all fitmnmm1 to fitmnmm~
      eval(parse(text = paste0('rm(', paste0(paste0('fitmnmm', seq(mnmm)), 
                                             collapse = ', '), ')')))
      
      tmp4 <- list(formula1 = mnmm, fit = fitmnmm)
      
    } else {
      eval(parse(text = paste0('wtfitmnmm <- list(', 
                               paste(paste0(nam, seq(mnmm), ' = ', 'wtfitmnmm', seq(mnmm)), 
                                     collapse = ', '), ')')))
      
      ## rm all wtfitmnmm1 to wtfitmnmm~
      eval(parse(text = paste0('rm(', paste0(paste0('wtfitmnmm', seq(mnmm)), 
                                             collapse = ', '), ')')))
      
      tmp4 <- list(formula1 = mnmm, fit = wtfitmnmm)
    }
    
    ## return if single family
    if(family == 'multinomial') return(tmp4)
    
    
  } else if((family == 'cox')|(family == 'all')) {
    ## ------------------------------ cox ---------------------------------
    ## 1 model : tmeasure = 'cox'
    tmeasure <- 'cox'
    family <- 'cox'
    wt.control = c(TRUE, FALSE)
    
    coxm <- sapply(xy.matrix, function(x) {
      sapply(yv, function(y) {
        sapply(tmeasure, function(z) {
          sapply(pred.type, function(xx) {
            sapply(s, function(xy) {
              sapply(setform, function(xz) {
                sapply(wt.control, function(yx) {
                  paste0('glmPrice(mbase, family = \'', family, '\', xy.matrix = \'', x, 
                         '\', setform = \'', xz, '\', yv = \'', y, '\', tmeasure = \'', z, 
                         '\', maxit = ', maxit, ', newx = newx, pred.type = \'', xx, 
                         '\', alpha = ', alpha, ', nfolds = ', nfolds, 
                         ', foldid = ', foldid, ', s = \'', xy, '\', fordate = fordate', 
                         ', weight.date = ', weight.date, ', weight.volume = ', 
                         weight.volume, ', wt.control = ', yx, 
                         ', parallel = ', parallel, ', .log = .log)')
                })
              })
            })
          })
        })
      })
    }) %>% as.character
    
    #'@ if(weight.date != FALSE | weight.volume!= FALSE) nam <- 'wtfitcoxm' else nam <- 'fitcoxm'
    if(weight.dist == 'pnorm') {
      nam <- 'wt.pnorm.fitcoxm'
    } else if(weight.dist == 'phalfcoxm'){
      nam <- 'wt.phalfnorm.fitcoxm'
    } else if(weight.dist == 'none') {
      nam <- 'fitcoxm'
    } else {
      stop('Kindly select weight.dist = "pnorm" or weight.dist = "phalfnorm" or weight.dist = "none".')
    }
    
    cm <- paste(paste0(
      nam, seq(coxm), " <- ", coxm, 
      "; if(.save == TRUE) saveRDS(", nam, seq(coxm), ", file = '", pth, "/", nam, seq(coxm), ".rds')", 
      "; if(.print == TRUE) cat('multinomial model ",  pth, ' : ', as.character(now()), ' : ', seq(coxm), "/", length(coxm), " ", txt, ".\n')"), 
      collapse = "; ")
    
    ## start algorithmic calculation.
    eval(parse(text = cm)); rm(cm)
    
    if(nam == 'fitcoxm') {
      ## combine all fitcoxm1 to fitcoxm~ into a list named fitcoxm
      eval(parse(text = paste0('fitcoxm <- list(', 
                               paste(paste0(nam, seq(coxm), ' = ', 'fitcoxm', seq(coxm)), 
                                     collapse = ', '), ')')))
      
      ## rm all fitcoxm1 to fitcoxm~
      eval(parse(text = paste0('rm(', paste0(paste0('fitcoxm', seq(coxm)), 
                                             collapse = ', '), ')')))
      
      tmp5 <- list(formula1 = coxm, fit = fitcoxm)
      
    } else {
      eval(parse(text = paste0('wtfitcoxm <- list(', 
                               paste(paste0(nam, seq(coxm), ' = ', 'wtfitcoxm', seq(coxm)), 
                                     collapse = ', '), ')')))
      
      ## rm all wtfitcoxm1 to wtfitcoxm~
      eval(parse(text = paste0('rm(', paste0(paste0('wtfitcoxm', seq(coxm)), 
                                             collapse = ', '), ')')))
      
      tmp5 <- list(formula1 = coxm, fit = wtfitcoxm)
    }
    
    ## return if single family
    if(family == 'cox') return(tmp5)
    
    
  }  else if((family == 'mgaussian')|(family == 'all')) {
    ## ------------------------- mgaussian --------------------------------
    ## 1 model : tmeasure = 'mgaussian'
    tmeasure <- 'mgaussian'
    family <- 'mgaussian'
    wt.control = c(TRUE, FALSE)
    
    mgam <- sapply(xy.matrix, function(x) {
      sapply(yv, function(y) {
        sapply(tmeasure, function(z) {
          sapply(pred.type, function(xx) {
            sapply(s, function(xy) {
              sapply(setform, function(xz) {
                sapply(wt.control, function(yx) {
                  paste0('glmPrice(mbase, family = \'', family, '\', xy.matrix = \'', x, 
                         '\', setform = \'', xz, '\', yv = \'', y, '\', tmeasure = \'', z, 
                         '\', maxit = ', maxit, ', newx = newx, pred.type = \'', xx, 
                         '\', alpha = ', alpha, ', nfolds = ', nfolds, 
                         ', foldid = ', foldid, ', s = \'', xy, '\', fordate = fordate', 
                         ', weight.date = ', weight.date, ', weight.volume = ', 
                         weight.volume, ', wt.control = ', yx, 
                         ', parallel = ', parallel, ', .log = .log)')
                })
              })
            })
          })
        })
      })
    }) %>% as.character
    
    #'@ if(weight.date != FALSE | weight.volume!= FALSE) nam <- 'wtfitmgam' else nam <- 'fitmgam'
    if(weight.dist == 'pnorm') {
      nam <- 'wt.pnorm.fitmgam'
    } else if(weight.dist == 'phalfmgam'){
      nam <- 'wt.phalfnorm.fitmgam'
    } else if(weight.dist == 'none') {
      nam <- 'fitmgam'
    } else {
      stop('Kindly select weight.dist = "pnorm" or weight.dist = "phalfnorm" or weight.dist = "none".')
    }
    
    mgm <- paste(paste0(
      nam, seq(mgam), " <- ", mgam, 
      "; if(.save == TRUE) saveRDS(", nam, seq(mgam), ", file = '", pth, "/", nam, seq(mgam), ".rds')", 
      "; if(.print == TRUE) cat('mgaussian model ",  pth, ' : ', as.character(now()), ' : ', seq(mgam), "/", length(mgam), " ", txt, ".\n')"), 
      collapse = "; ")
    
    ## start algorithmic calculation.
    eval(parse(text = mgm)); rm(mgm)
    
    if(nam == 'fitmgam') {
      ## combine all fitmgam1 to fitmgam~ into a list named fitmgam
      eval(parse(text = paste0('fitmgam <- list(', 
                               paste(paste0(nam, seq(mgam), ' = ', 'fitmgam', seq(mgam)), 
                                     collapse = ', '), ')')))
      
      ## rm all fitmgam1 to fitmgam~
      eval(parse(text = paste0('rm(', paste0(paste0('fitmgam', seq(mgam)), 
                                             collapse = ', '), ')')))
      
      tmp6 <- list(formula1 = mgam, fit = fitmgam)
      
    } else {
      eval(parse(text = paste0('wtfitmgam <- list(', 
                               paste(paste0(nam, seq(mgam), ' = ', 'wtfitmgam', seq(mgam)), 
                                     collapse = ', '), ')')))
      
      ## rm all wtfitmgam1 to wtfitmgam~
      eval(parse(text = paste0('rm(', paste0(paste0('wtfitmgam', seq(mgam)), 
                                             collapse = ', '), ')')))
      
      tmp6 <- list(formula1 = mgam, fit = wtfitmgam)
    }
    
    ## return if single family
    if(family == 'mgaussian') return(tmp6)
    
    
    }else {
    stop('Kindly select family = "gaussian", family = "binomial", family = "poisson", family = "multinomial", family = "cox" or family = "mgaussian".')
  }
  
  ## ======================== Return Function ================================
  ## return all famalies.
  tmp <- list(fitgaum = tmp1, fitbinm = tmp2, fitpoim = tmp3, 
              fitmnmm = tmp4, fitcoxm = tmp5, fitmgam = tmp6)
  #'@ rm(tmp1, tmp2, tmp3, tmp4, tmp5, tmp6)
  
  ## remove all include hidden objects but only leave one object.
  rm(list = setdiff(ls(all.names = TRUE), 'tmp'))
  return(tmp)
}

